/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::{collections::BTreeMap, fmt::Display};

use super::TypedValue;

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

impl<const N: usize> From<[(TypedValue, Option<TypedValue>); N]> for BigMap {
    fn from(mapping: [(TypedValue, Option<TypedValue>); N]) -> Self {
        BigMap {
            id: None,
            overlay: BTreeMap::from(mapping),
        }
    }
}

impl<const N: usize> From<[(TypedValue, TypedValue); N]> for BigMap {
    fn from(mapping: [(TypedValue, TypedValue); N]) -> Self {
        BigMap {
            id: None,
            overlay: mapping.into_iter().map(|(k, v)| (k, Some(v))).collect(),
        }
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
/// Note that in Octez implementation, work with this layer is observable. When
/// you call a contract with `octez-client`, you can see, for instance:
///
/// ```txt
/// Updated storage: (Pair 69183 70325)
/// Updated big_maps:
///   Clear map(69179)
///   New map(70325) of type (big_map int int)
///   Set map(69183)[5] to 5
/// ```
///
/// So we try to mimic what Octez does, and do it carefully so that if we also
/// need to log actions done at this layer, it would be close to what Octez
/// does.
pub trait LazyStorage {
    /// Get a value under the given key of the given big map.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    fn big_map_get(
        &self,
        id: BigMapId,
        key: &TypedValue,
    ) -> Result<Option<TypedValue>, LazyStorageError>;

    /// Check whether a value is present under the given key of the given big
    /// map.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    fn big_map_mem(&self, id: BigMapId, key: &TypedValue) -> Result<bool, LazyStorageError> {
        self.big_map_get(id, key).map(|x| x.is_some())
    }

    /// Add or remove a value in big map, accepts `Option` as value like in
    /// Michelson.
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
    fn big_map_update(
        &mut self,
        id: BigMapId,
        key: TypedValue,
        value: Option<TypedValue>,
    ) -> Result<(), LazyStorageError>;

    /// Update big map with multiple changes, generalizes
    /// [LazyStorage::big_map_update].
    ///
    /// The specified big map id must point to a valid map in the lazy storage.
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

    /// Allocate a new empty big map.
    fn big_map_new(&mut self) -> Result<BigMapId, LazyStorageError>;

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

/// Simple implementation for [LazyStorage].
pub struct InMemoryLazyStorage {
    next_id: usize,
    big_maps: BTreeMap<BigMapId, BTreeMap<TypedValue, TypedValue>>,
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
    fn access_big_map(
        &self,
        id: BigMapId,
    ) -> Result<&BTreeMap<TypedValue, TypedValue>, LazyStorageError> {
        self.big_maps
            .get(&id)
            .ok_or_else(|| panic!("Non-existent big map by id {id}"))
    }

    fn access_big_map_mut(
        &mut self,
        id: BigMapId,
    ) -> Result<&mut BTreeMap<TypedValue, TypedValue>, LazyStorageError> {
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
        let map = self.access_big_map(id)?;
        Ok(map.get(key).cloned())
    }

    fn big_map_update(
        &mut self,
        id: BigMapId,
        key: TypedValue,
        value: Option<TypedValue>,
    ) -> Result<(), LazyStorageError> {
        let map = self.access_big_map_mut(id)?;
        match value {
            None => {
                map.remove(&key);
            }
            Some(value) => {
                map.insert(key, value);
            }
        }
        Ok(())
    }

    fn big_map_new(&mut self) -> Result<BigMapId, LazyStorageError> {
        let id = self.get_next_id();
        self.big_maps.insert(id, BTreeMap::new());
        Ok(id)
    }

    fn big_map_remove(&mut self, id: BigMapId) -> Result<(), LazyStorageError> {
        self.big_maps.remove(&id);
        Ok(())
    }

    fn big_map_copy(&mut self, copied_id: BigMapId) -> Result<BigMapId, LazyStorageError> {
        let id = self.get_next_id();
        let map = self.big_maps.get(&copied_id).unwrap().clone();
        self.big_maps.insert(id, map);
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
        let map = BigMap::from([(TypedValue::Int(1), TypedValue::Int(1))]);

        check_get_mem(&map, storage, TypedValue::Int(0), None);
        check_get_mem(&map, storage, TypedValue::Int(1), Some(TypedValue::Int(1)));
    }

    #[test]
    fn test_get_mem_backed_by_storage() {
        let storage = &mut InMemoryLazyStorage::new();
        let map_id = storage.big_map_new().unwrap();
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
        };

        check_get_mem(&map, storage, TypedValue::Int(0), Some(TypedValue::Int(0)));
        check_get_mem(&map, storage, TypedValue::Int(1), Some(TypedValue::Int(-1)));
        check_get_mem(&map, storage, TypedValue::Int(2), None);
        check_get_mem(&map, storage, TypedValue::Int(3), Some(TypedValue::Int(3)));
    }
}
