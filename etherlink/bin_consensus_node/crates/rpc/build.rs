fn main() -> Result<(), Box<dyn std::error::Error>> {
    Ok(tonic_build::compile_protos("proto/dsn.proto")?)
}
