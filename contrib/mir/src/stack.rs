/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::ops::{Index, IndexMut};
use std::slice::SliceIndex;

use crate::ast::*;

pub type TypeStack = Stack<Type>;
pub type IStack = Stack<Value>;

/// Construct a `Stack` with the given content. Note that stack top is the
/// _rightmost_ element.
macro_rules! stk {
    [$($args:tt)*] => {
        crate::stack::Stack::from(vec![$($args)*])
    };
}

pub(crate) use stk;

/// A stack abstraction based on `Vec`.
#[derive(Debug, PartialEq, Eq, Clone)]
pub struct Stack<T>(Vec<T>);

impl<T> Stack<T> {
    /// Allocate a new empty stack.
    pub fn new() -> Stack<T> {
        Stack::from(Vec::new())
    }

    /// Convert stack index to vec index.
    fn vec_index(&self, i: usize) -> usize {
        let len = self.len();
        len.checked_sub(i + 1).expect("out of bounds stack access")
    }

    /// Push an element onto the top of the stack.
    pub fn push(&mut self, elt: T) {
        self.0.push(elt)
    }

    /// Pop an element off the top of the stack.
    pub fn pop(&mut self) -> Option<T> {
        self.0.pop()
    }

    /// Get the stack's element count.
    pub fn len(&self) -> usize {
        self.0.len()
    }

    /// Removes the specified number of elements from the top of the stack in
    /// bulk.
    ///
    /// Panics if the `size` is larger than length of the stack.
    pub fn drop_top(&mut self, size: usize) -> () {
        let len = self.len();
        self.0
            .truncate(len.checked_sub(size).expect("size too large in drop_top"));
    }

    /// Borrow the stack content as an immutable slice. Note that stack top is
    /// the _rightmost_ element.
    pub fn as_slice(&self) -> &[T] {
        self.0.as_slice()
    }

    /// Borrow the stack content as a mutable slice. Note that stack top is
    /// the _rightmost_ element.
    pub fn as_mut_slice(&mut self) -> &mut [T] {
        self.0.as_mut_slice()
    }

    /// Split off the top `size` elements of the stack into a new `Stack`.
    ///
    /// Panics if the `size` is larger than length of the stack.
    pub fn split_off(&mut self, size: usize) -> Stack<T> {
        let len = self.len();
        Stack::from(
            self.0
                .split_off(len.checked_sub(size).expect("size too large in split_off")),
        )
    }

    /// Move elements from `other` to the top of the stack. New stack top is the
    /// top of `other`. Note that elements are moved out of `other`.
    pub fn append(&mut self, other: &mut Stack<T>) -> () {
        self.0.append(&mut other.0)
    }

    /// Swap two elements in the stack, identified by their index from the top,
    /// with `0` being the top.
    pub fn swap(&mut self, i1: usize, i2: usize) -> () {
        let i1v = self.vec_index(i1);
        let i2v = self.vec_index(i2);
        self.0.swap(i1v, i2v)
    }
}

impl<T> From<Vec<T>> for Stack<T> {
    fn from(data: Vec<T>) -> Self {
        Stack(data)
    }
}

impl<T> Index<usize> for Stack<T> {
    type Output = <usize as SliceIndex<[T]>>::Output;

    /// Index into the stack. The top's index is `0`. Returns an immutable
    /// reference to the element.
    fn index(&self, index: usize) -> &Self::Output {
        self.0.index(self.vec_index(index))
    }
}

impl<T> IndexMut<usize> for Stack<T> {
    /// Index into the stack. The top's index is `0`. Returns a mutable
    /// reference to the element.
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        self.0.index_mut(self.vec_index(index))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stk_macro() {
        assert_eq!(stk![1, 2, 3, 4], Stack::from(vec![1, 2, 3, 4]));
        assert_eq!(stk![1; 5], Stack::from(vec![1, 1, 1, 1, 1]));
    }

    #[test]
    fn push() {
        let mut stk = Stack::new();
        stk.push(1);
        stk.push(2);
        stk.push(3);
        assert_eq!(stk, stk![1, 2, 3]);
    }

    #[test]
    fn pop() {
        let mut stk = stk![1, 2, 3];
        assert_eq!(stk.pop(), Some(3));
        assert_eq!(stk.pop(), Some(2));
        assert_eq!(stk.pop(), Some(1));
        assert_eq!(stk.pop(), None);
    }

    #[test]
    fn len() {
        let mut stk = stk![1, 2, 3];
        assert_eq!(stk.len(), 3);
        stk.push(42);
        assert_eq!(stk.len(), 4);
    }

    #[test]
    fn drop_top() {
        let mut stk = stk![1, 2, 3, 4];
        stk.drop_top(3);
        assert_eq!(stk, stk![1]);
    }

    #[test]
    #[should_panic(expected = "size too large in drop_top")]
    fn drop_top_out_of_bounds() {
        let mut stk = stk![1, 2, 3, 4];
        stk.drop_top(42);
    }

    #[test]
    fn as_slice() {
        let stk = stk![1, 2, 3, 4];
        assert!(matches!(stk.as_slice(), [1, 2, 3, 4]));
    }

    #[test]
    fn as_mut_slice() {
        let mut stk = stk![1, 2, 3, 4];
        match stk.as_mut_slice() {
            [.., i] => *i = 42,
            _ => unreachable!("Slice is non-empty by construction"),
        }
        assert_eq!(stk, stk![1, 2, 3, 42]);
    }

    #[test]
    fn split_off() {
        let mut stk = stk![1, 2, 3, 4, 5];
        let stk2 = stk.split_off(3);
        assert_eq!(stk2, stk![3, 4, 5]);
        assert_eq!(stk, stk![1, 2]);
    }

    #[test]
    #[should_panic(expected = "size too large in split_off")]
    fn split_off_out_of_bounds() {
        let mut stk = stk![1, 2, 3, 4, 5];
        stk.split_off(42);
    }

    #[test]
    fn append() {
        let mut stk1 = stk![1, 2, 3];
        let mut stk2 = stk![4, 5];
        stk1.append(&mut stk2);
        assert_eq!(stk1, stk![1, 2, 3, 4, 5]);
        assert_eq!(stk2, stk![]);
    }

    #[test]
    fn index() {
        let stk = stk![1, 2, 3, 4, 5];
        assert_eq!(stk[0], 5);
        assert_eq!(stk[4], 1);
    }

    #[test]
    #[should_panic(expected = "out of bounds stack access")]
    fn index_out_of_bounds() {
        let stk = stk![1, 2, 3, 4, 5];
        assert_eq!(stk[7], 5); // panics
    }

    #[test]
    fn index_mut() {
        let mut stk = stk![1, 2, 3, 4, 5];
        stk[2] = 42;
        assert_eq!(stk, stk![1, 2, 42, 4, 5]);
    }
}
