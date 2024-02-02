mod rv32i;
mod rv64i;

#[cfg(test)]
pub mod tests {
    use super::{rv32i, rv64i};
    use crate::backend::tests::TestBackendFactory;

    pub fn test<F: TestBackendFactory>() {
        rv32i::tests::test::<F>();
        rv64i::tests::test::<F>();
    }
}
