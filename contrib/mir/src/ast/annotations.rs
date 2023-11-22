/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use crate::lexer::Annotation;

#[derive(Clone, Eq, PartialEq)]
pub struct Annotations<'a>(Vec<Annotation<'a>>);

pub const NO_ANNS: Annotations = Annotations::new();

#[derive(Debug, Clone, Eq, PartialEq, thiserror::Error)]
pub enum AnnotationError {
    #[error("unexpected second field annotation: {0}")]
    TooManyFieldAnns(String),
}

impl Default for Annotations<'_> {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Debug for Annotations<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

pub struct FieldAnnotation<'a>(&'a str);

impl FieldAnnotation<'_> {
    pub fn as_str(&self) -> &str {
        self.0
    }
}

impl<'a> Annotations<'a> {
    pub const fn new() -> Self {
        Annotations(Vec::new())
    }

    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    pub fn get_single_field_ann(&self) -> Result<Option<FieldAnnotation<'a>>, AnnotationError> {
        use Annotation::*;
        let mut res = None;
        for i in &self.0 {
            match i {
                Special(..) | Type(..) | Variable(..) => (), // special annotations
                Field(s) => {
                    // field annotations
                    if res.is_none() {
                        res = Option::Some(FieldAnnotation(*s));
                    } else {
                        return Err(AnnotationError::TooManyFieldAnns(s.to_string()));
                    }
                }
            }
        }
        Ok(res)
    }
}

impl<'a, T> From<T> for Annotations<'a>
where
    T: AsRef<[Annotation<'a>]>,
{
    fn from(x: T) -> Self {
        Annotations(Vec::from(x.as_ref()))
    }
}

impl<'a> FromIterator<Annotation<'a>> for Annotations<'a> {
    fn from_iter<T: IntoIterator<Item = Annotation<'a>>>(iter: T) -> Self {
        Annotations(Vec::from_iter(iter))
    }
}
