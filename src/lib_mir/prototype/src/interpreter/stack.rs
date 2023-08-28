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
        assert!(stk![1, 2, 3, 4, 5].data == vec![5, 4, 3, 2, 1])
    }
}

#[derive(Debug, PartialEq, Eq)]
pub struct Stack<T> {
    data: Vec<T>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum FStack<T> {
    Ok(Stack<T>),
    Failed,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FailedStackAccess;

impl<T> FStack<T> {
    pub fn access(&self) -> Option<&Stack<T>> {
        match self {
            FStack::Ok(v) => Some(v),
            FStack::Failed => None,
        }
    }
    pub fn access_val(self) -> Option<Stack<T>> {
        match self {
            FStack::Ok(v) => Some(v),
            FStack::Failed => None,
        }
    }
    pub fn access_mut(&mut self) -> Option<&mut Stack<T>> {
        match self {
            FStack::Ok(v) => Some(v),
            FStack::Failed => None,
        }
    }

    pub fn fail(&mut self) {
        *self = FStack::Failed
    }
}

impl<T> Stack<T> {
    #[inline]
    pub fn new(data: Vec<T>) -> Stack<T> {
        Stack::from(data)
    }

    #[inline]
    pub fn push(&mut self, elt: T) {
        self.data.push(elt)
    }

    #[inline]
    pub fn pop(&mut self) -> Option<T> {
        self.data.pop()
    }

    #[inline]
    pub fn get(&self, depth: usize) -> Option<&T> {
        self.data.get(self.len() - depth)
    }

    #[inline]
    pub fn get_mut(&mut self, depth: usize) -> Option<&mut T> {
        let len = self.len();
        self.data.get_mut(len - depth)
    }

    #[inline]
    pub fn len(&self) -> usize {
        self.data.len()
    }

    #[inline]
    pub fn drain_top(&mut self, size: usize) -> Drain<'_, T> {
        let len = self.len();
        self.data.drain(len - size..)
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
            let mut protected = self.data.split_off(len - depth);
            let res = f(self);
            self.data.append(&mut protected);
            res
        }
    }

    #[inline]
    pub fn reserve(&mut self, n: usize) {
        self.data.reserve(n)
    }

    #[inline]
    pub fn remove(&mut self, i: usize) -> T {
        let len = self.len();
        self.data.remove(len - i - 1)
    }

    #[inline]
    pub fn insert(&mut self, i: usize, elt: T) {
        let len = self.len();
        self.data.insert(len - i, elt)
    }

    #[inline]
    pub fn top(&self) -> Option<&T> {
        self.data.last()
    }

    #[inline]
    pub fn top_mut(&mut self) -> Option<&mut T> {
        self.data.last_mut()
    }
}

impl<T> FStack<T> {
    pub fn protect<R, F: FnOnce(&mut Self) -> R>(
        &mut self,
        depth: usize,
        f: F,
    ) -> Result<R, FailedStackAccess> {
        // redundant check - sad; at this point this should already be checked
        let stack = self.access_mut().ok_or(FailedStackAccess)?;
        debug_assert!(depth < stack.len());
        if depth == 1 {
            // small optimization that avoids unnecessary allocations
            let protected = stack.pop().unwrap();
            let res = f(self);
            self.access_mut().ok_or(FailedStackAccess)?.push(protected);
            Ok(res)
        } else {
            let len = stack.len();
            let mut protected = stack.data.split_off(len - depth);
            let res = f(self);
            self.access_mut()
                .ok_or(FailedStackAccess)?
                .data
                .append(&mut protected);
            Ok(res)
        }
    }
}
impl<T> Extend<T> for Stack<T> {
    #[inline]
    fn extend<I: IntoIterator<Item = T>>(&mut self, iter: I) {
        self.data.extend(iter)
    }
}

impl<T: Clone> Clone for Stack<T> {
    #[inline]
    fn clone(&self) -> Self {
        Stack {
            data: self.data.clone(),
        }
    }
}

impl<T> From<Vec<T>> for Stack<T> {
    #[inline]
    fn from(data: Vec<T>) -> Self {
        Stack { data }
    }
}

impl<T> From<Vec<T>> for FStack<T> {
    #[inline]
    fn from(data: Vec<T>) -> Self {
        FStack::Ok(data.into())
    }
}

impl<T> From<Stack<T>> for Vec<T> {
    #[inline]
    fn from(st: Stack<T>) -> Self {
        st.data
    }
}

impl<T> TryFrom<FStack<T>> for Vec<T> {
    type Error = FailedStackAccess;

    #[inline]
    fn try_from(value: FStack<T>) -> Result<Self, Self::Error> {
        value.access_val().ok_or(FailedStackAccess).map(Vec::from)
    }
}
