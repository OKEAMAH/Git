/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::ops::{Deref, DerefMut, Index, IndexMut};
use std::ptr::NonNull;
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

pub struct Stack<T> {
    data: std::ptr::NonNull<T>,
    cap: usize,
    head: usize,
}

impl<T> Drop for Stack<T> {
    fn drop(&mut self) {
        if self.cap != 0 {
            let layout = std::alloc::Layout::array::<T>(self.cap).unwrap();
            self.clear();
            unsafe { std::alloc::dealloc(self.data.as_ptr() as *mut u8, layout) };
            self.data = NonNull::dangling();
            self.cap = 0;
            self.head = 0;
        }
    }
}

impl<T: std::fmt::Debug> std::fmt::Debug for Stack<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("stk!")?;
        f.debug_list().entries(self.as_slice().iter()).finish()
    }
}

impl<T: PartialEq> PartialEq for Stack<T> {
    fn eq(&self, other: &Stack<T>) -> bool {
        self.as_slice() == other.as_slice()
    }
}

impl<T: Eq> Eq for Stack<T> {}

impl<T> From<Vec<T>> for Stack<T> {
    fn from(v: Vec<T>) -> Self {
        let mut s = Stack::<T>::new();
        let len = v.len();
        s.cap = v.capacity();
        s.data = NonNull::new(v.leak().as_mut_ptr()).unwrap();
        s.head = s.cap - len;
        if len != s.cap {
            // move to end
            unsafe {
                std::ptr::copy(
                    s.data.as_ptr(),
                    s.data.as_ptr().offset((s.head) as isize),
                    len,
                )
            };
        }
        s
    }
}

impl<T> Deref for Stack<T> {
    type Target = [T];
    fn deref(&self) -> &[T] {
        unsafe { std::slice::from_raw_parts(self.head_ptr(), self.len()) }
    }
}

impl<T> DerefMut for Stack<T> {
    fn deref_mut(&mut self) -> &mut [T] {
        unsafe { std::slice::from_raw_parts_mut(self.head_mut_ptr(), self.len()) }
    }
}

impl<T, I: SliceIndex<[T]>> Index<I> for Stack<T> {
    type Output = <I as SliceIndex<[T]>>::Output;

    fn index(&self, index: I) -> &Self::Output {
        &self.deref()[index]
    }
}

impl<T, I: SliceIndex<[T]>> IndexMut<I> for Stack<T> {
    fn index_mut(&mut self, index: I) -> &mut Self::Output {
        &mut self.deref_mut()[index]
    }
}

impl<T> Stack<T> {
    pub fn new() -> Stack<T> {
        Stack {
            data: NonNull::dangling(),
            cap: 0,
            head: 0,
        }
    }

    fn grow(&mut self, size: usize) {
        if self.cap < size {
            if self.cap == 0 {
                let layout = std::alloc::Layout::array::<T>(size).unwrap();
                unsafe {
                    self.data =
                        std::ptr::NonNull::new(std::alloc::alloc(layout) as *mut T).unwrap();
                    self.cap = size;
                    self.head = size;
                }
            } else {
                let old_layout = std::alloc::Layout::array::<T>(self.cap).unwrap();
                let new_layout = std::alloc::Layout::array::<T>(size).unwrap();
                unsafe {
                    self.data = std::ptr::NonNull::new(std::alloc::realloc(
                        self.data.as_ptr() as *mut u8,
                        old_layout,
                        new_layout.size(),
                    ) as *mut T)
                    .unwrap();
                    let ptr = self.data.as_ptr();
                    std::ptr::copy(
                        ptr.offset(self.head as isize),
                        ptr.offset((size - self.len()) as isize),
                        self.len(),
                    );
                }
                self.head += size - self.cap;
                self.cap = size;
            }
        }
    }

    unsafe fn head_ptr(&self) -> *const T {
        self.data.as_ptr().offset(self.head as isize)
    }

    unsafe fn head_mut_ptr(&mut self) -> *mut T {
        self.data.as_ptr().offset(self.head as isize)
    }

    pub fn push(&mut self, e: T) {
        if self.head == 0 {
            self.grow(std::cmp::max(8, self.cap * 2));
        }
        debug_assert!(self.head > 0);
        unsafe {
            self.head -= 1;
            std::ptr::write(self.head_mut_ptr(), e);
        }
    }

    pub fn pop(&mut self) -> Option<T> {
        if self.head < self.cap {
            unsafe {
                let r = self.head_ptr();
                self.head += 1;
                Some(std::ptr::read(r))
            }
        } else {
            None
        }
    }

    pub fn len(&self) -> usize {
        self.cap - self.head
    }

    pub fn drop_top(&mut self, size: usize) -> () {
        if size > self.len() {
            panic!("size too large in drop_top");
        }
        let s = &mut self[..size];
        unsafe { std::ptr::drop_in_place(s) };
        self.head += size;
    }

    pub fn as_slice(&self) -> &[T] {
        &*self
    }

    pub fn as_mut_slice(&mut self) -> &mut [T] {
        &mut *self
    }

    pub fn split_off(&mut self, size: usize) -> Stack<T> {
        if size > self.len() {
            panic!("size too large in split_off")
        }
        let mut r = Stack::new();
        r.grow(size);
        unsafe { std::ptr::copy_nonoverlapping(self.head_ptr(), r.data.as_mut(), size) }
        r.head = r.cap - size;
        self.head += size;
        r
    }

    pub fn append(&mut self, other: &mut Stack<T>) -> () {
        let other_len = other.len();
        self.grow(other_len + self.cap);
        self.head -= other_len;
        unsafe { std::ptr::copy_nonoverlapping(other.head_ptr(), self.head_mut_ptr(), other_len) }
        other.clear();
    }

    pub fn swap(&mut self, i1: usize, i2: usize) -> () {
        let a = std::ptr::addr_of_mut!(self[i1]);
        let b = std::ptr::addr_of_mut!(self[i2]);
        unsafe {
            std::ptr::swap(a, b);
        }
    }

    /// Clear the stack without freeing the buffer.
    pub fn clear(&mut self) -> () {
        unsafe { std::ptr::drop_in_place(self.as_mut_slice()) }
        self.head = self.cap;
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
        assert_eq!(stk.as_slice(), stk![1, 2, 3, 4, 5, 6].as_slice());
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
        assert_eq!(stk2, stk![]);
    }

    #[test]
    fn index() {
        let stk = stk![1, 2, 3, 4, 5];
        assert_eq!(stk[0], 1);
        assert_eq!(stk[4], 5);
    }

    #[test]
    #[should_panic(expected = "index out of bounds")]
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

    #[test]
    fn debug() {
        assert_eq!(format!("{:?}", stk![1, 2, 3]), "stk![1, 2, 3]")
    }
}
