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

#[derive(Debug, Clone)]
pub struct Stack<T: Default> {
    data: Vec<T>,
    head: usize,
}

impl<T: Default + Clone + Copy + PartialEq> PartialEq for Stack<T> {
    fn eq(&self, other: &Stack<T>) -> bool {
        self.as_slice() == other.as_slice()
    }
}

impl<T: Default + Clone> From<Vec<T>> for Stack<T> {
    fn from(v: Vec<T>) -> Self {
        return Stack { data: v, head: 0 };
    }
}

impl<T: Default + Clone + Copy> Index<usize> for Stack<T> {
    type Output = <usize as SliceIndex<[T]>>::Output;

    fn index(&self, index: usize) -> &Self::Output {
        if index >= self.len() {
            panic!("out of bounds stack access")
        }
        self.data.index(self.head + index)
    }
}

impl<T: Copy + Clone + Default> IndexMut<usize> for Stack<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        if index >= self.len() {
            panic!("out of bounds stack access")
        }
        self.data.index_mut(self.head + index)
    }
}

impl<T: Default + Clone + Copy> Stack<T> {
    pub fn new() -> Stack<T> {
        let v = Stack::from(vec![]);
        return v;
    }

    pub fn resize_data(&mut self, size: usize) {
        if self.data.capacity() < size {
            let mut vec = Vec::with_capacity(size);
            unsafe { vec.set_len(size - self.data.len()) };
            vec.extend_from_slice(self.data.as_slice());
            self.head = self.head + (size - self.data.len());
            self.data = vec;
        }
    }

    pub fn push(&mut self, e: T) {
        if self.head > 0 {
            self.head = self.head - 1;
            self.data[self.head] = e;
        } else {
            if self.data.len() == 0 {
                self.resize_data(2);
            } else {
                self.resize_data(self.data.capacity() * 20);
            }
            self.push(e);
        }
    }

    pub fn pop(&mut self) -> Option<T> {
        if self.head < self.data.len() {
            let r = self.data[self.head].clone();
            self.head = self.head + 1;
            return Some(r);
        } else {
            None
        }
    }

    pub fn len(&self) -> usize {
        self.data.len() - self.head
    }

    pub fn drop_top(&mut self, size: usize) -> () {
        if size > self.len() {
            panic!("size too large in drop_top");
        }
        self.head = self.head + size;
    }

    pub fn as_slice(&self) -> &[T] {
        return &self.data[self.head..];
    }

    pub fn as_mut_slice(&mut self) -> &mut [T] {
        return &mut self.data[self.head..];
    }

    pub fn split_off(&mut self, size: usize) -> Stack<T> {
        if size > self.len() {
            panic!("size too large in split_off")
        }
        let mut r = Stack::new();
        for i in 0..size {
            r.push(self[size - 1 - i]);
        }
        self.head = self.head + size;
        return r;
    }

    pub fn append(&mut self, other: &mut Stack<T>) -> () {
        let other_len = other.len();
        let mut offset: usize = 0;
        self.resize_data(other_len + self.data.capacity());
        for i in other.as_slice() {
            self.data[self.head - other_len + offset] = *i;
            offset = offset + 1;
        }
        self.head = self.head - other.len();
    }

    pub fn swap(&mut self, i1: usize, i2: usize) -> () {
        self.data.swap(self.head + i1, self.head + i2);
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
        stk.push(6);
        stk.push(5);
        stk.push(4);
        stk.push(3);
        stk.push(2);
        stk.push(1);
        assert_eq!(stk, stk![1, 2, 3, 4, 5, 6]);
    }

    #[test]
    fn pop() {
        let mut stk = stk![1, 2, 3];
        assert_eq!(stk.pop(), Some(1));
        assert_eq!(stk.pop(), Some(2));
        assert_eq!(stk.pop(), Some(3));
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
        assert_eq!(stk, stk![4]);
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
        assert_eq!(stk2, stk![1, 2, 3]);
        assert_eq!(stk, stk![4, 5]);
    }

    #[test]
    #[should_panic(expected = "size too large in split_off")]
    fn split_off_out_of_bounds() {
        let mut stk = stk![1, 2, 3, 4, 5];
        stk.split_off(42);
    }

    #[test]
    fn append() {
        let mut stk1 = stk![3, 4, 5];
        let mut stk2 = stk![1, 2];
        stk1.append(&mut stk2);
        assert_eq!(stk1, stk![1, 2, 3, 4, 5]);
        //assert_eq!(stk2, stk![]);
    }

    #[test]
    fn index() {
        let stk = stk![1, 2, 3, 4, 5];
        assert_eq!(stk[0], 1);
        assert_eq!(stk[4], 5);
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
