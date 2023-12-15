/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::{
    collections::{btree_map::Entry, BTreeMap},
    fmt::Display,
    mem,
    ops::DerefMut,
};

use super::{Type, TypedValue};

/// Id of big map in the lazy storage.
#[derive(Copy, Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct BigMapId(usize);

impl Display for BigMapId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Represents a big_map value.
///
/// Big map is split into two parts - one is in the lazy storage, and another is
/// an in-memory overlay that carries a diff from the map in the storage.
#[derive(Debug, Clone, Eq, PartialEq)]
pub struct BigMap {
    /// Id of the big map in the lazy storage.
    ///
    /// Big map can be backed by no map in the lazy storage and yet stay fully
    /// in memory, in such case this field is `None`.
    id: Option<BigMapId>,

    /// In-memory part, carries the diff that is to be applied to the map in the
    /// storage.
    ///
    /// Normally, execution of all writing instructions update this part, and at
    /// certain key points like the end of the contract execution this diff is
    /// dumped into the storage. Change in storage can be applied in-place or,
    /// if necessary, with copy of the stored map.
    overlay: BTreeMap<TypedValue, Option<TypedValue>>,

    key_type: Type,
    value_type: Type,
}

impl BigMap {
    /// Michelson's `GET`.
    pub fn get(
        &self,
        key: &TypedValue,
        storage: &impl LazyStorage,
    ) -> Result<Option<TypedValue>, LazyStorageError> {
        Ok(match (self.id, self.overlay.get(key)) {
            (_, Some(change)) => change.clone(),
            (Some(id), None) => storage.big_map_get(id, key)?,
            (None, None) => None,
        })
    }

    /// Michelson's `MEM`.
    pub fn mem(
        &self,
        key: &TypedValue,
        storage: &impl LazyStorage,
    ) -> Result<bool, LazyStorageError> {
        Ok(match (self.id, self.overlay.get(key)) {
            (_, Some(change)) => change.is_some(),
            (Some(id), None) => storage.big_map_mem(id, key)?,
            (None, None) => false,
        })
    }

    /// Michelson's `UPDATE`.
    pub fn update(&mut self, key: TypedValue, value: Option<TypedValue>) {
        self.overlay.insert(key, value);
    }
}

#[derive(Debug, PartialEq, Eq, Clone, thiserror::Error)]
pub enum LazyStorageError {
    #[error("decode failed {0}")]
    DecodingError(String),
    #[error("{0}")]
    OtherError(String),
}

/// All the operations for working with the lazy storage.
///
/// Note that in the Tezos protocol implementation, work with this layer is
/// observable. When you call a contract with `octez-client`, you can see, for
/// instance:
///
/// ```txt
/// Updated storage: (Pair 69183 70325)
/// Updated big_maps:
///   Clear map(69179)
///   New map(70325) of type (big_map int int)
///   Set map(69183)[5] to 5
/// ```
///
/// So we try to mimic what the Tezos protocol does, and do it carefully so that
/// if we also need to log actions done at this layer, it would be close to what
/// the Tezos protocol does.
pub trait LazyStorage {
    /// Get a value under the given key of the given big map.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    /// Key type must match the type of key of the stored map.
    fn big_map_get(
        &self,
        id: BigMapId,
        key: &TypedValue,
    ) -> Result<Option<TypedValue>, LazyStorageError>;

    /// Check whether a value is present under the given key of the given big
    /// map.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    /// Key type must match the type of key of the stored map.
    fn big_map_mem(&self, id: BigMapId, key: &TypedValue) -> Result<bool, LazyStorageError> {
        self.big_map_get(id, key).map(|x| x.is_some())
    }

    /// Add or remove a value in big map, accepts `Option` as value like in
    /// Michelson.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    /// Key and value types must match the type of key of the stored map.
    fn big_map_update(
        &mut self,
        id: BigMapId,
        key: TypedValue,
        value: Option<TypedValue>,
    ) -> Result<(), LazyStorageError>;

    /// Get key and value types of the map.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    fn big_map_get_type(&self, id: BigMapId) -> Result<(&Type, &Type), LazyStorageError>;

    /// Allocate a new empty big map.
    fn big_map_new(
        &mut self,
        key_type: &Type,
        value_type: &Type,
    ) -> Result<BigMapId, LazyStorageError>;

    /// Allocate a new big map, filling it with the contents from another map
    /// in the lazy storage.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    fn big_map_copy(&mut self, id: BigMapId) -> Result<BigMapId, LazyStorageError>;

    /// Remove a big map.
    ///
    /// The caller is obliged to never use this big map ID in the given
    /// storage.
    fn big_map_remove(&mut self, id: BigMapId) -> Result<(), LazyStorageError>;
}

pub trait LazyStorageBulkUpdate: LazyStorage {
    /// Update big map with multiple changes, generalizes
    /// [LazyStorage::big_map_update].
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    /// Key and value types must match the type of key of the stored map.
    fn big_map_bulk_update(
        &mut self,
        id: BigMapId,
        entries_iter: impl IntoIterator<Item = (TypedValue, Option<TypedValue>)>,
    ) -> Result<(), LazyStorageError> {
        for (k, v) in entries_iter {
            self.big_map_update(id, k, v)?
        }
        Ok(())
    }
}

impl<T: LazyStorage> LazyStorageBulkUpdate for T {}

#[derive(Clone, PartialEq, Eq, Debug)]
pub struct MapInfo {
    map: BTreeMap<TypedValue, TypedValue>,
    key_type: Type,
    value_type: Type,
}

/// Simple implementation for [LazyStorage].
#[derive(Clone)]
pub struct InMemoryLazyStorage {
    next_id: usize,
    big_maps: BTreeMap<BigMapId, MapInfo>,
}

impl InMemoryLazyStorage {
    pub fn new() -> InMemoryLazyStorage {
        InMemoryLazyStorage {
            next_id: 0,
            big_maps: BTreeMap::new(),
        }
    }

    fn get_next_id(&mut self) -> BigMapId {
        let id = BigMapId(self.next_id);
        self.next_id += 1;
        id
    }
}

impl Default for InMemoryLazyStorage {
    fn default() -> Self {
        InMemoryLazyStorage::new()
    }
}

impl InMemoryLazyStorage {
    fn access_big_map(&self, id: BigMapId) -> Result<&MapInfo, LazyStorageError> {
        self.big_maps
            .get(&id)
            .ok_or_else(|| panic!("Non-existent big map by id {id}"))
    }

    fn access_big_map_mut(&mut self, id: BigMapId) -> Result<&mut MapInfo, LazyStorageError> {
        self.big_maps
            .get_mut(&id)
            .ok_or_else(|| panic!("Non-existent big map by id {id}"))
    }
}

impl LazyStorage for InMemoryLazyStorage {
    fn big_map_get(
        &self,
        id: BigMapId,
        key: &TypedValue,
    ) -> Result<Option<TypedValue>, LazyStorageError> {
        let info = self.access_big_map(id)?;
        Ok(info.map.get(key).cloned())
    }

    fn big_map_update(
        &mut self,
        id: BigMapId,
        key: TypedValue,
        value: Option<TypedValue>,
    ) -> Result<(), LazyStorageError> {
        let info = self.access_big_map_mut(id)?;
        match value {
            None => {
                info.map.remove(&key);
            }
            Some(value) => {
                info.map.insert(key, value);
            }
        }
        Ok(())
    }

    fn big_map_get_type(&self, id: BigMapId) -> Result<(&Type, &Type), LazyStorageError> {
        let info = self.access_big_map(id)?;
        Ok((&info.key_type, &info.value_type))
    }

    fn big_map_new(
        &mut self,
        key_type: &Type,
        value_type: &Type,
    ) -> Result<BigMapId, LazyStorageError> {
        let id = self.get_next_id();
        self.big_maps.insert(
            id,
            MapInfo {
                map: BTreeMap::new(),
                key_type: key_type.clone(),
                value_type: value_type.clone(),
            },
        );
        Ok(id)
    }

    fn big_map_remove(&mut self, id: BigMapId) -> Result<(), LazyStorageError> {
        self.big_maps.remove(&id);
        Ok(())
    }

    fn big_map_copy(&mut self, copied_id: BigMapId) -> Result<BigMapId, LazyStorageError> {
        let id = self.get_next_id();
        let info = self.access_big_map(copied_id)?.clone();
        self.big_maps.insert(id, info);
        Ok(id)
    }
}

/// This will also implement [LazyStorage].
///
/// Worth mentioning, that this type will eventually wrap `&mut impl Runtime`
/// (or rather `&mut R (where R: Runtime)` which has to be a mere reference,
/// this `Runtime` will provide access to rollup's persistent storage. And this
/// potentially indicates some problems for us.
///
/// * We will have to put this storage to the context, meaning that in `Ctx` we
///   will have to account for lifetimes and for the `R` generic argument.
/// * One cannot put `&mut impl Runtime` twice into context because of borrowing
///   restrictions. So trying to have e.g. `RollupStorage` as one context field,
///   and some `OriginatedContractParameterGetter` that also works via `Runtime`
///   as another context field won't be possible. We may end up with the entire
///   `Ctx` implementing all the traits that our engine should be polymorphic
///   over (`LazyStorage` is probably one of them), which is ugly and
///   boilerplat-y.
/// * The caller may have a similar problem - he will have to give
///   typechecker/interpreter's context exclusive access to `Runtime`. We will
///   have to make sure it doesn't restrict the caller from e.g. writing
///   something to the storage between typechecker and interpreter calls.
#[allow(dead_code)]
struct RollupStorage();

#[cfg(test)]
mod test_big_map_operations {
    use super::*;

    fn check_get_mem(
        map: &BigMap,
        storage: &mut impl LazyStorage,
        key: TypedValue,
        expected_val: Option<TypedValue>,
    ) {
        assert_eq!(map.get(&key, storage).unwrap(), expected_val);
        assert_eq!(map.mem(&key, storage).unwrap(), expected_val.is_some());
    }

    #[test]
    fn test_get_mem_in_memory() {
        let storage = &mut InMemoryLazyStorage::new();
        let map = BigMap {
            id: None,
            overlay: BTreeMap::from([(TypedValue::Int(1), Some(TypedValue::Int(1)))]),
            key_type: Type::Int,
            value_type: Type::Int,
        };

        check_get_mem(&map, storage, TypedValue::Int(0), None);
        check_get_mem(&map, storage, TypedValue::Int(1), Some(TypedValue::Int(1)));
    }

    #[test]
    fn test_get_mem_backed_by_storage() {
        let storage = &mut InMemoryLazyStorage::new();
        let map_id = storage.big_map_new(&Type::Int, &Type::Int).unwrap();
        storage
            .big_map_update(map_id, TypedValue::Int(0), Some(TypedValue::Int(0)))
            .unwrap();
        storage
            .big_map_update(map_id, TypedValue::Int(1), Some(TypedValue::Int(1)))
            .unwrap();
        storage
            .big_map_update(map_id, TypedValue::Int(2), Some(TypedValue::Int(2)))
            .unwrap();
        let map = BigMap {
            id: Some(map_id),
            overlay: BTreeMap::from([
                (TypedValue::Int(1), Some(TypedValue::Int(-1))),
                (TypedValue::Int(2), None),
                (TypedValue::Int(3), Some(TypedValue::Int(3))),
            ]),
            key_type: Type::Int,
            value_type: Type::Int,
        };

        check_get_mem(&map, storage, TypedValue::Int(0), Some(TypedValue::Int(0)));
        check_get_mem(&map, storage, TypedValue::Int(1), Some(TypedValue::Int(-1)));
        check_get_mem(&map, storage, TypedValue::Int(2), None);
        check_get_mem(&map, storage, TypedValue::Int(3), Some(TypedValue::Int(3)));
    }
}

impl TypedValue {
    fn view_big_maps_ext<'a>(&'a mut self, put_res: &mut impl FnMut(&'a mut BigMap)) {
        use crate::ast::Or::*;
        use TypedValue::*;
        fn go<'a>(val: &'a mut TypedValue, put_res: &mut impl FnMut(&'a mut BigMap)) {
            match val {
                Int(_) => {}
                Nat(_) => {}
                Mutez(_) => {}
                Bool(_) => {}
                Unit => {}
                String(_) => {}
                Bytes(_) => {}
                Address(_) => {}
                KeyHash(_) => {}
                Key(_) => {}
                Signature(_) => {}
                ChainId(_) => {}
                Contract(_) => {}
                Pair(p) => {
                    go(&mut p.0, put_res);
                    go(&mut p.1, put_res);
                }
                Or(p) => match p.deref_mut() {
                    Left(l) => go(l, put_res),
                    Right(r) => go(r, put_res),
                },
                Option(p) => match p {
                    Some(x) => go(x, put_res),
                    None => {}
                },
                List(l) => l.iter_mut().for_each(|v| go(v, put_res)),
                Set(_) => {
                    // Elements are comparable and so have no big maps
                }
                Map(m) => m.iter_mut().for_each(|(_k, v)| {
                    // Key is comparable as so has no big map, skipping it
                    go(v, put_res)
                }),
                // TODO: next merge request
                // actually take some big maps once they are present in TypedValue
                Operation(op) => match &mut op.as_mut().operation {
                    crate::ast::Operation::TransferTokens(t) => {
                        go(&mut t.param, put_res);
                    }
                    crate::ast::Operation::SetDelegate(_) => {}
                },
            }
        }
        go(self, put_res);
    }

    pub fn view_big_maps_mut<'a>(&'a mut self, out: &mut Vec<&'a mut BigMap>) {
        self.view_big_maps_ext(&mut |m| out.push(m));
    }

    pub fn view_big_map_ids<T>(&mut self, out: &mut Vec<BigMapId>) {
        self.view_big_maps_ext(&mut |m| {
            if let Some(id) = m.id {
                out.push(id)
            }
        });
    }
}

/// Given big map IDs before contract execution and big maps after the
/// execution, dump all the updates to the lazy storage. All the big maps
/// remaining unused will be removed from the storage.
///
/// After the call, [BigMap::overlay] field in all provided big maps is
/// guaranteed to be empty and all [BigMap::id]s are guaranteed to be non-None.
/// Also, some [BigMap::id] fields may change to avoid duplications.
pub fn dump_big_map_updates(
    storage: &mut impl LazyStorage,
    started_with_map_ids: &[BigMapId],
    finished_with_maps: &mut [&mut BigMap],
) -> Result<(), LazyStorageError> {
    // Note: this function is similar to `extract_lazy_storage_diff` from the
    // Tezos protocol implementation. The difference is that we don't have
    // their's `to_duplicate` argument.
    //
    // Temporarily we go with a simpler solution where each ID in
    // `started_with_map_ids` is guaranteed to be used by only one big map, a
    // big map that comes from parameter or storage value; these IDs are
    // expected to be not used by big maps in other contracts. Consequences of
    // this:
    // * If a contract produces an operation with a big map, we immediately
    // deduplicate big map ID there too (the Tezos protocol implementation does
    // not).
    // * There is no need to implement temporary lazy storage for now.

    // The `finished_with_maps` vector above is supposed to contain all big maps
    // remaining on stack at the end of contract execution. After this function
    // call, we want the provided big maps to satisfy the following invariants:
    // * No `BigMapId` appears twice. This ensures that a big map in the storage
    //   cannot be updated in-parallel via different `Value::BigMap` values.
    // * Big maps, whose IDs are gone, are removed from the lazy storage.
    // * Best effort is made to avoid copying big maps in the lazy storage, big
    //   maps are updated in-place when possible.

    // First, we find big maps that are related to same big map IDs in the
    // storage. This is necessary to understand which maps will be updated in
    // lazy storage in-place and which have to be copied.
    //
    // With big map IDs we associate a non-empty list of big maps.
    // Where "non-empty" is kept `(T, Vec<T>)` for convenience. Note
    // that in the vast majority of the real-life cases big maps are not
    // de-facto copied, so the vector will usually stay empty and produce no
    // allocations.
    type NonEmpty<T> = (T, Vec<T>);
    let mut grouped_maps: BTreeMap<BigMapId, NonEmpty<&mut BigMap>> = BTreeMap::new();

    for map in finished_with_maps {
        match map.id {
            Some(id) => {
                // Insert to grouped_maps
                match grouped_maps.entry(id) {
                    Entry::Vacant(e) => {
                        e.insert((map, Vec::new()));
                    }
                    Entry::Occupied(e) => e.into_mut().1.push(map),
                }
            }
            None => {
                // ID is empty, meaning that the entire big map is still in
                // memory. We have to create a new map in the storage.
                let id = storage.big_map_new(&map.key_type, &map.value_type)?;
                storage.big_map_bulk_update(id, mem::take(&mut map.overlay))?;
                map.id = Some(id)
            }
        };
    }

    // Remove big maps that were gone.
    for map_id in started_with_map_ids {
        // If not found in `finished_with_maps`...
        if !grouped_maps.contains_key(map_id) {
            storage.big_map_remove(*map_id)?
        }
    }

    // Update lazy storage with data from overlay.
    for (id, (main_map, other_maps)) in grouped_maps {
        // If there are any big maps with duplicate ID, we first copy them in
        // the storage.
        for map in other_maps {
            let new_id = storage.big_map_copy(id)?;
            storage.big_map_bulk_update(new_id, mem::take(&mut map.overlay))?;
            map.id = Some(new_id)
        }
        // The only remaining big map we update in the lazy storage in-place.
        storage.big_map_bulk_update(id, mem::take(&mut main_map.overlay))?
    }

    Ok(())
}

#[cfg(test)]
mod test_big_map_to_storage_update {
    use crate::ast::Type;

    use super::*;

    #[track_caller]
    fn check_is_dumped_map(map: BigMap, id: BigMapId) {
        assert_eq!((map.id, map.overlay), (Some(id), BTreeMap::new()));
    }

    #[test]
    fn test_map_from_memory() {
        let storage = &mut InMemoryLazyStorage::new();
        let mut map = BigMap {
            id: None,
            overlay: BTreeMap::from([
                (TypedValue::Int(1), Some(TypedValue::Int(1))),
                (TypedValue::Int(2), Some(TypedValue::Int(2))),
            ]),
            key_type: Type::Int,
            value_type: Type::Int,
        };
        dump_big_map_updates(storage, &[], &mut [&mut map]).unwrap();

        check_is_dumped_map(map, BigMapId(0));
        assert_eq!(
            storage.big_maps,
            BTreeMap::from([(
                BigMapId(0),
                MapInfo {
                    map: BTreeMap::from([
                        (TypedValue::Int(1), TypedValue::Int(1)),
                        (TypedValue::Int(2), TypedValue::Int(2))
                    ]),
                    key_type: Type::Int,
                    value_type: Type::Int
                }
            )])
        )
    }

    #[test]
    fn test_map_updates_to_storage() {
        let storage = &mut InMemoryLazyStorage::new();
        let map_id = storage.big_map_new(&Type::Int, &Type::Int).unwrap();
        storage
            .big_map_update(map_id, TypedValue::Int(0), Some(TypedValue::Int(0)))
            .unwrap();
        storage
            .big_map_update(map_id, TypedValue::Int(1), Some(TypedValue::Int(1)))
            .unwrap();
        let mut map = BigMap {
            id: Some(map_id),
            overlay: BTreeMap::from([
                (TypedValue::Int(0), None),
                (TypedValue::Int(1), Some(TypedValue::Int(5))),
                (TypedValue::Int(2), None),
                (TypedValue::Int(3), Some(TypedValue::Int(3))),
            ]),
            key_type: Type::Int,
            value_type: Type::Int,
        };
        dump_big_map_updates(storage, &[], &mut [&mut map]).unwrap();

        check_is_dumped_map(map, BigMapId(0));
        assert_eq!(
            storage.big_maps,
            BTreeMap::from([(
                BigMapId(0),
                MapInfo {
                    map: BTreeMap::from([
                        (TypedValue::Int(1), TypedValue::Int(5)),
                        (TypedValue::Int(3), TypedValue::Int(3))
                    ]),
                    key_type: Type::Int,
                    value_type: Type::Int
                }
            )])
        )
    }

    #[test]
    fn test_duplicate_ids() {
        let storage = &mut InMemoryLazyStorage::new();
        let map_id1 = storage.big_map_new(&Type::Int, &Type::Int).unwrap();
        let map_id2 = storage.big_map_new(&Type::Int, &Type::Int).unwrap();
        let mut map1_1 = BigMap {
            id: Some(map_id1),
            overlay: BTreeMap::from([(TypedValue::Int(11), Some(TypedValue::Int(11)))]),
            key_type: Type::Int,
            value_type: Type::Int,
        };
        let mut map1_2 = BigMap {
            id: Some(map_id1),
            overlay: BTreeMap::from([(TypedValue::Int(12), Some(TypedValue::Int(12)))]),
            key_type: Type::Int,
            value_type: Type::Int,
        };
        let mut map2 = BigMap {
            id: Some(map_id2),
            overlay: BTreeMap::from([(TypedValue::Int(2), Some(TypedValue::Int(2)))]),
            key_type: Type::Int,
            value_type: Type::Int,
        };
        dump_big_map_updates(storage, &[], &mut [&mut map1_1, &mut map1_2, &mut map2]).unwrap();

        check_is_dumped_map(map1_1, BigMapId(0));
        check_is_dumped_map(map1_2, BigMapId(2)); // newly created map
        check_is_dumped_map(map2, BigMapId(1));

        assert_eq!(
            storage.big_maps,
            BTreeMap::from([
                (
                    BigMapId(0),
                    MapInfo {
                        map: BTreeMap::from([(TypedValue::Int(11), TypedValue::Int(11))]),
                        key_type: Type::Int,
                        value_type: Type::Int
                    }
                ),
                (
                    BigMapId(1),
                    MapInfo {
                        map: BTreeMap::from([(TypedValue::Int(2), TypedValue::Int(2))]),
                        key_type: Type::Int,
                        value_type: Type::Int
                    }
                ),
                (
                    BigMapId(2),
                    MapInfo {
                        map: BTreeMap::from([(TypedValue::Int(12), TypedValue::Int(12))]),
                        key_type: Type::Int,
                        value_type: Type::Int
                    }
                )
            ])
        );
    }

    #[test]
    fn test_remove_ids() {
        let storage = &mut InMemoryLazyStorage::new();
        let map_id1 = storage.big_map_new(&Type::Int, &Type::Int).unwrap();
        storage
            .big_map_update(map_id1, TypedValue::Int(0), Some(TypedValue::Int(0)))
            .unwrap();
        let map_id2 = storage.big_map_new(&Type::Int, &Type::Int).unwrap();
        storage
            .big_map_update(map_id2, TypedValue::Int(0), Some(TypedValue::Int(0)))
            .unwrap();
        let mut map1 = BigMap {
            id: Some(map_id1),
            overlay: BTreeMap::from([(TypedValue::Int(1), Some(TypedValue::Int(1)))]),
            key_type: Type::Int,
            value_type: Type::Int,
        };
        dump_big_map_updates(storage, &[map_id1, map_id2], &mut [&mut map1]).unwrap();

        assert_eq!(
            storage.big_maps,
            BTreeMap::from([(
                BigMapId(0),
                MapInfo {
                    map: BTreeMap::from([
                        (TypedValue::Int(0), TypedValue::Int(0)),
                        (TypedValue::Int(1), TypedValue::Int(1))
                    ]),
                    key_type: Type::Int,
                    value_type: Type::Int
                }
            )])
        );
    }
}
