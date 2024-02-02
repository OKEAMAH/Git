mod rv32i;
mod rv64i;

#[cfg(test)]
pub mod tests {
    use super::rv64i;
    use crate::backend::tests::TestBackendFactory;

    pub fn test<F: TestBackendFactory>() {
        rv64i::tests::test::<F>();
    }
}
