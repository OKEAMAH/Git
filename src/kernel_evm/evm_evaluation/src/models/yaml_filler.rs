
use std::path::Path;
use std::collections::HashMap;
use std::str::FromStr;
use anyhow::{anyhow, Result};
use serde_yaml::{from_slice as yaml_from_slice, Value};
use serde::Deserialize;
use primitive_types::{H160, H256, U256};

fn value_to_i64(v: &Value) -> Result<i64> {
    match v {
        Value::Number(ref n) => {
            n.as_i64().map(|i| Ok(i)).unwrap_or(Err(anyhow!("Number value {:?} is not i64", v)))
        }
        Value::String(s) => s.parse::<i64>().map_err(|err| anyhow!("Got error parsing i64: {:?}", err)),
        Value::Sequence(v) if v.len() > 0 => value_to_i64(&v[0]),
        _ => Err(anyhow!("Cannot turn {:?} into i64", v)),
    }
}

fn value_to_bool(v: &Value) -> Result<bool> {
    todo!()
}

fn value_to_u256(v: &Value) -> Result<U256> {
    match v {
        Value::Number(ref n) => {
            n.as_i64().map(|i| Ok(i.into())).unwrap_or(Err(anyhow!("Number value {:?} is neither u256 nor i64", v)))
        }
        Value::String(s) => U256::from_str(&s).map_err(|err| anyhow!("U256 parse error: {:?}", err)),
        Value::Sequence(v) if v.len() > 0 => value_to_u256(&v[0]),
        _ => Err(anyhow!("Cannot turn {:?} into u256", v)),
    }
}

fn value_to_h256(v: &Value) -> Result<H256> {
    match v {
        Value::Number(_) => {
            Err(anyhow!("Cannot parse H256 from {:?}", v))
        }
        Value::String(s) => H256::from_str(&s).map_err(|err| anyhow!("H256 parse error: {:?}", err)),
        Value::Sequence(v) if v.len() > 0 => value_to_h256(&v[0]),
        _ => Err(anyhow!("Cannot turn {:?} into h256", v)),
    }

}

fn value_to_h160(v: &Value) -> Result<H160> {
    match v {
        Value::Number(_) => {
            Err(anyhow!("Cannot parse H160 from {:?}", v))
        }
        Value::String(s) => H160::from_str(&s).map_err(|err| anyhow!("H160 parse error: {:?}", err)),
        Value::Sequence(v) if v.len() > 0 => value_to_h160(&v[0]),
        _ => Err(anyhow!("Cannot turn {:?} into h160", v)),
    }
}

fn value_to_string(v: &Value) -> Result<String> {
    match v {
        Value::String(s) => Ok(s.to_string()),
        Value::Sequence(v) if v.len() > 0 => value_to_string(&v[0]),
        _ => Err(anyhow!("Could not make {:?} into a string", v)),
    }
}

#[derive(Debug, Deserialize, Clone)]
pub struct Index {
    data: Option<Value>,
    gas: Option<Value>,
    value: Option<Value>,
}

impl Index {
    pub fn data(&self) -> Result<Option<i64>> {
        self.data.as_ref().map_or(Ok(None), |v| value_to_i64(&v).map(Some))
    }

    pub fn gas(&self) -> Result<Option<i64>> {
        self.gas.as_ref().map_or(Ok(None), |v| value_to_i64(&v).map(Some))
    }

    pub fn value(&self) -> Result<Option<i64>> {
        self.value.as_ref().map_or(Ok(None), |v| value_to_i64(&v).map(Some))
    }
}

#[derive(Debug, Deserialize)]
pub struct AccountState {
    nonce: Option<Value>, // should be U256
    balance: Option<Value>, // should be U256
    storage: Option<HashMap<Value, Value>>,
    shouldnotexist: Option<Value>,
}

impl AccountState {
    pub fn nonce(&self) -> Result<Option<U256>> {
        self.nonce.as_ref().map_or(Ok(None), |v| value_to_u256(&v).map(Some))
    }

    pub fn balance(&self) -> Result<Option<U256>> {
        self.balance.as_ref().map_or(Ok(None), |v| value_to_u256(&v).map(Some))
    }

    pub fn storage(&self) -> Result<Option<HashMap<H256, H256>>> {
        self.storage.as_ref().map_or(Ok(None), |s| {
            todo!()
        })
    }

    pub fn should_not_exist(&self) -> Result<Option<bool>> {
        self.shouldnotexist.as_ref().map_or(Ok(None), |v| value_to_bool(&v).map(Some))
    }
}

#[derive(Debug, Deserialize)]
pub struct Expectation {
    indexes: Option<Index>,
    network: Vec<Value>,
    result: HashMap<Value, AccountState>,
}

impl Expectation {
    pub fn indexes(&self) -> Option<Index> {
        self.indexes.clone()
    }

    pub fn network(&self) -> Result<Vec<String>> {
        let mut res = Vec::new();

        for n in &self.network {
            res.push(value_to_string(&n)?);
        }

        Ok(res)
    }

    pub fn result(&self) -> Result<HashMap<H160, AccountState>> {
        todo!()
    }
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
