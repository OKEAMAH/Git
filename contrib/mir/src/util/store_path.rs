//! Provides utilities for working with durable storage paths (keys).

use std::fmt::Display;
use std::ops::Div;
use tezos_smart_rollup_host::path::{Path, RefPath, PATH_SEPARATOR};

/// Things that can participate in path construction.
///
/// For instance, an address type can implement this trait, and then a path for
/// storing balance of an address can be
/// ```
/// PathBuilder::root() / b"balance" / addr
/// ```
trait PathSegment {
    /// Add to the given vector the appropriate bytes representation of the
    /// object.
    ///
    /// This must append at least one byte to the vector. Must append a sequence
    /// of either ascii-encoded alphanumeric bytes, or `b'.'` or `b'_'` or `b'-'
    fn add_path_segment(self, base: &mut Vec<u8>);
}

impl PathSegment for &[u8] {
    fn add_path_segment(self, acc: &mut Vec<u8>) {
        acc.extend(self)
    }
}

impl<const N: usize> PathSegment for &[u8; N] {
    fn add_path_segment(self, acc: &mut Vec<u8>) {
        acc.extend(self)
    }
}

// [optimization]: in most cases paths have known fixed length, we can
// potentially save some allocations by exploiting that fact.

/// Builder for durable storage keys.
#[derive(Clone, Eq, PartialEq, Ord, PartialOrd, Debug)]
pub struct PathBuilder {
    path: Vec<u8>,
}

impl Display for PathBuilder {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("<path>")
    }
}

impl PathBuilder {
    pub fn root() -> PathBuilder {
        PathBuilder { path: Vec::new() }
    }
}

unsafe impl Path for PathBuilder {
    // SAFETY: requires the path to satisfy a set of predicates, which is
    // ensured by checking with to [RefPath].
    fn as_bytes(&self) -> &[u8] {
        let _ = RefPath::assert_from(&self.path);
        &self.path
    }
}

impl<T: PathSegment> Div<T> for PathBuilder {
    type Output = PathBuilder;
    fn div(mut self, seg: T) -> Self {
        self.path.push(PATH_SEPARATOR);
        PathSegment::add_path_segment(seg, &mut self.path);
        self
    }
}

#[cfg(test)]
mod test_paths {
    use tezos_smart_rollup_host::runtime::Runtime;
    use tezos_smart_rollup_mock::MockHost;

    use super::*;

    #[test]
    fn test_basic() {
        use PathBuilder as PB;

        let path = PB::root() / b"abc" / b"def";
        let _ = MockHost::default().store_has(&path);
    }

    #[test]
    fn test_from_array_ref() {
        use PathBuilder as PB;

        let path = PB::root() / String::from("def").as_bytes();
        let _ = MockHost::default().store_has(&path);
    }
}
