
use std::path::Path;
use std::collections::HashMap;
use anyhow::{anyhow, Result};
use serde_yaml::{from_slice as yaml_from_slice, Value};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Index {
    data: i32,
    gas: i32,
    value: i32,
}

#[derive(Debug, Deserialize)]
pub struct AccountState {
    nonce: Option<Value>, // should be U256
    balance: Option<Value>, // should be U256
    storage: Option<HashMap<String, Value>>,
    shouldnotexist: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct Expectation {
    indexes: Index,
    network: Vec<String>,
    result: HashMap<String, AccountState>,
}

#[derive(Debug, Deserialize)]
pub struct Filler {
    name: String,
    expectations: Vec<Expectation>,
}

fn yaml_string(v: &Value) -> String {
    match v {
        Value::String(s) => s.to_string(),
        Value::Sequence(v) => yaml_string(&v[0]),
        _ => {
            println!("Got a mystery: {:?}", v);
            "mystery-name".to_string()
        }
    }
}

fn post_expectations(v: &Value) -> Result<Vec<Expectation>> {
    match &v["expect"] {
        Value::Sequence(s) => {
            s.iter()
                .map(|i| {
                    Expectation::deserialize(i)
                        .map_err(|err| anyhow!("oh bugger! {:?}", err))
                })
                .collect()
            // s.iter().map(|i| parse_expectation(i)).collect()
        }
        _ => Err(anyhow!("Argh - was expecting a sequence of expectations")),
    }
}

fn post_conditions(filler_data: Value) -> Result<Vec<Filler>> {
    match filler_data {
        Value::Mapping(mapping) => {
            mapping.iter().map(|key_value| {
                let key = key_value.0;
                let value = key_value.1;

                Ok(Filler {
                    name: yaml_string(key),
                    expectations: post_expectations(value)?,
                })
            }).collect()
        }
        _ => Err(anyhow!("I don't get it - test-filler yaml is weird"))
    }
}

pub fn read_filler(filename: &str) -> Result<Vec<Filler>> {
    let data: serde_yaml::Value = yaml_from_slice(&std::fs::read(Path::new(filename))?)?;
    post_conditions(data)
}
