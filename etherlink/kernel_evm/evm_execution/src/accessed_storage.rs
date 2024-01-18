use alloc::collections::btree_set::BTreeSet;
use primitive_types::{H160, H256};

#[derive(Eq, Clone, PartialOrd, PartialEq, Ord)]
struct AddressIndex(H160, H256);

#[derive(Clone)]
pub struct AccessedStorage(BTreeSet<AddressIndex>);

impl AccessedStorage {
    pub fn new() -> Self {
        AccessedStorage(BTreeSet::new())
    }

    pub fn insert(&mut self, address: H160, index: H256) {
        self.0.insert(AddressIndex(address, index));
    }

    pub fn contains(&self, address: H160, index: H256) -> bool {
        self.0.contains(&AddressIndex(address, index))
    }
}
