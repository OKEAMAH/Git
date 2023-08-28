/******************************************************************************/
/*                                                                            */
/* MIT License                                                                */
/* Copyright (c) 2023 Serokell <hi@serokell.io>                               */
/*                                                                            */
/* Permission is hereby granted, free of charge, to any person obtaining a    */
/* copy of this software and associated documentation files (the "Software"), */
/* to deal in the Software without restriction, including without limitation  */
/* the rights to use, copy, modify, merge, publish, distribute, sublicense,   */
/* and/or sell copies of the Software, and to permit persons to whom the      */
/* Software is furnished to do so, subject to the following conditions:       */
/*                                                                            */
/* The above copyright notice and this permission notice shall be included    */
/* in all copies or substantial portions of the Software.                     */
/*                                                                            */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR */
/* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    */
/* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    */
/* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER        */
/* DEALINGS IN THE SOFTWARE.                                                  */
/*                                                                            */
/******************************************************************************/

use std::vec::Drain;

macro_rules! stk {
    (;; $acc:tt) => {
        crate::interpreter::stack::Stack::new(vec!$acc)
    };
    ($e:expr $(, $es:expr)* $(,)* ;; [ $($acc:expr),* ]) => {
        crate::interpreter::stack::stk!($($es),* ;; [$e $(, $acc)*])
    };
    ($($es:expr),* $(,)*) => {
        crate::interpreter::stack::stk!($($es),* ;; [])
    };
    ($e:expr; $n:literal) => {
        crate::interpreter::stack::Stack::new(vec![$e; $n])
    };
}

pub(crate) use stk;

#[cfg(test)]
pub mod test {
    #[test]
    fn test() {
        assert!(stk![1, 2, 3, 4, 5].access() == &vec![5, 4, 3, 2, 1])
    }
}

#[derive(Debug)]
pub struct Stack<T> {
    data: Vec<T>,
    failed: bool,
}

#[inline]
fn guard<R>(cond: bool, res: R) -> Option<R> {
    if cond {
        Some(res)
    } else {
        None
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FailedStackAccess;

impl<T> Stack<T> {
    #[inline]
    pub fn new(data: Vec<T>) -> Stack<T> {
        Stack::from(data)
    }

    #[inline]
    pub fn is_ok(&self) -> bool {
        !self.failed
    }

    #[inline]
    pub fn is_failed(&self) -> bool {
        self.failed
    }

    #[inline]
    pub fn fail(&mut self) {
        self.failed = true;
    }

    #[inline]
    pub fn access(&self) -> &Vec<T> {
        debug_assert!(self.is_ok());
        &self.data
    }

    #[inline]
    pub fn access_val(self) -> Vec<T> {
        debug_assert!(self.is_ok());
        self.data
    }

    #[inline]
    pub fn access_mut(&mut self) -> &mut Vec<T> {
        debug_assert!(self.is_ok());
        &mut self.data
    }

    #[inline]
    pub fn try_access(&self) -> Option<&Vec<T>> {
        guard(self.is_ok(), &self.data)
    }

    #[inline]
    pub fn try_access_val(self) -> Option<Vec<T>> {
        guard(self.is_ok(), self.data)
    }

    #[inline]
    pub fn try_access_mut(&mut self) -> Option<&mut Vec<T>> {
        guard(self.is_ok(), &mut self.data)
    }

    #[inline]
    pub fn push(&mut self, elt: T) {
        self.access_mut().push(elt)
    }

    #[inline]
    pub fn pop(&mut self) -> Option<T> {
        self.access_mut().pop()
    }

    #[inline]
    pub fn get(&self, depth: usize) -> Option<&T> {
        self.access().get(self.len() - depth)
    }

    #[inline]
    pub fn get_mut(&mut self, depth: usize) -> Option<&mut T> {
        let len = self.len();
        self.access_mut().get_mut(len - depth)
    }

    #[inline]
    pub fn len(&self) -> usize {
        self.access().len()
    }

    #[inline]
    pub fn drain_top(&mut self, size: usize) -> Drain<'_, T> {
        let len = self.len();
        self.access_mut().drain(len - size..)
    }

    pub fn protect<R, F: FnOnce(&mut Self) -> R>(&mut self, depth: usize, f: F) -> R {
        debug_assert!(depth < self.len());
        if depth == 1 {
            // small optimization that avoids unnecessary allocations
            let protected = self.pop().unwrap();
            let res = f(self);
            self.push(protected);
            res
        } else {
            let len = self.len();
            let mut protected = self.access_mut().split_off(len - depth);
            let res = f(self);
            self.access_mut().append(&mut protected);
            res
        }
    }

    #[inline]
    pub fn reserve(&mut self, n: usize) {
        self.access_mut().reserve(n)
    }

    #[inline]
    pub fn remove(&mut self, i: usize) -> T {
        let len = self.len();
        self.access_mut().remove(len - i - 1)
    }

    #[inline]
    pub fn insert(&mut self, i: usize, elt: T) {
        let len = self.len();
        self.access_mut().insert(len - i, elt)
    }

    #[inline]
    pub fn top(&self) -> Option<&T> {
        self.access().last()
    }

    #[inline]
    pub fn top_mut(&mut self) -> Option<&mut T> {
        self.access_mut().last_mut()
    }
}

impl<T> Extend<T> for Stack<T> {
    #[inline]
    fn extend<I: IntoIterator<Item = T>>(&mut self, iter: I) {
        self.access_mut().extend(iter)
    }
}

impl<T: Clone> Clone for Stack<T> {
    #[inline]
    fn clone(&self) -> Self {
        Stack {
            data: self.data.clone(),
            failed: self.failed,
        }
    }
}

impl<T> From<Vec<T>> for Stack<T> {
    #[inline]
    fn from(data: Vec<T>) -> Self {
        Stack {
            data,
            failed: false,
        }
    }
}

impl<T> TryFrom<Stack<T>> for Vec<T> {
    type Error = FailedStackAccess;

    #[inline]
    fn try_from(value: Stack<T>) -> Result<Self, Self::Error> {
        value.try_access_val().ok_or(FailedStackAccess)
    }
}

impl<T: PartialEq> PartialEq for Stack<T> {
    #[inline]
    fn eq(&self, other: &Self) -> bool {
        self.failed == other.failed && self.data == other.data
    }
}
