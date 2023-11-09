use super::AddressError;

#[derive(Debug, Clone, Eq, PartialOrd, Ord, PartialEq)]
pub struct Entrypoint(String);

// NB: default entrypoint is represented as literal "default", because it
// affects comparision for addresses.
const DEFAULT_EP_NAME: &str = "default";
const MAX_EP_LEN: usize = 31;

impl Default for Entrypoint {
    fn default() -> Self {
        Entrypoint(DEFAULT_EP_NAME.to_owned())
    }
}

impl Entrypoint {
    pub fn is_default(&self) -> bool {
        self.0 == DEFAULT_EP_NAME
    }

    pub fn as_bytes(&self) -> &[u8] {
        self.0.as_bytes()
    }

    pub fn as_str(&self) -> &str {
        self.0.as_str()
    }
}

impl TryFrom<&str> for Entrypoint {
    type Error = AddressError;
    fn try_from(s: &str) -> Result<Self, Self::Error> {
        Entrypoint::try_from(s.to_owned())
    }
}

impl TryFrom<String> for Entrypoint {
    type Error = AddressError;
    fn try_from(s: String) -> Result<Self, Self::Error> {
        if s.is_empty() {
            Ok(Entrypoint::default())
        } else {
            check_ep_name(s.as_bytes())?;
            Ok(Entrypoint(s))
        }
    }
}

impl TryFrom<&[u8]> for Entrypoint {
    type Error = AddressError;
    fn try_from(s: &[u8]) -> Result<Self, AddressError> {
        if s.is_empty() {
            Ok(Entrypoint::default())
        } else {
            check_ep_name(s)?;
            // SAFETY: we just checked all bytes are valid ASCII
            let ep = Entrypoint(unsafe { std::str::from_utf8_unchecked(s).to_owned() });
            if ep.is_default() {
                return Err(AddressError::WrongFormat(
                    "explicit default entrypoint is forbidden in binary encoding".to_owned(),
                ));
            }
            Ok(ep)
        }
    }
}

fn check_ep_name(ep: &[u8]) -> Result<(), AddressError> {
    if ep.len() > MAX_EP_LEN {
        return Err(AddressError::WrongFormat(format!(
            "entrypoint name must be at most {} characters long, but it is {} characters long",
            MAX_EP_LEN,
            ep.len()
        )));
    }
    let mut first_char = true;
    for c in ep {
        // direct encoding of the regex defined in
        // https://tezos.gitlab.io/alpha/michelson.html#syntax
        match c {
            b'_' | b'0'..=b'9' | b'a'..=b'z' | b'A'..=b'Z' => Ok(()),
            b'.' | b'%' | b'@' if !first_char => Ok(()),
            c => Err(AddressError::WrongFormat(format!(
                "forbidden byte in entrypoint name: {}",
                hex::encode([*c])
            ))),
        }?;
        first_char = false;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_check_ep_name() {
        assert_eq!(check_ep_name(&[b'q'; 31]), Ok(()));

        // more than 31 bytes
        assert!(matches!(
            check_ep_name(&[b'q'; 32]),
            Err(AddressError::WrongFormat(_))
        ));

        // '.', '%', '@' are allowed
        for i in ['.', '%', '@'] {
            assert_eq!(check_ep_name(format!("foo{i}bar").as_bytes()), Ok(()));

            // but not as the first character
            assert!(matches!(
                check_ep_name(format!("{i}bar").as_bytes()),
                Err(AddressError::WrongFormat(_))
            ));
        }

        // ! is forbidden
        assert!(matches!(
            check_ep_name(b"foo!"),
            Err(AddressError::WrongFormat(_))
        ));

        // unicode is forbidden
        assert!(matches!(
            check_ep_name("नमस्ते".as_bytes()),
            Err(AddressError::WrongFormat(_))
        ));
    }
}
