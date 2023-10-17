use evm::executor::stack::StackExecutor;
use primitive_types::H160;
use evm::Config;
use tezos_smart_rollup_host::runtime::Runtime;
use evm::executor::stack::PrecompileSet;
use crate::backend::RollupBackend;
use evm::executor::stack::MemoryStackState;
use evm::executor::stack::StackSubstateMetadata;

pub type RollupStackState<'a, 'config, 'backend, Host> = MemoryStackState<'backend, 'config, RollupBackend<'a, Host>>;

pub fn new_executor<'a, 'config, 'backend, 'precompiles, Host: Runtime, P>(
    backend: &'backend RollupBackend<'a, Host>,
    config: &'config Config,
    precompiles: &'precompiles P,
    origin: H160,
    gas_limit: u64,
) -> StackExecutor<'config, 'precompiles, RollupStackState<'a, 'config, 'backend, Host>, P>
where P: PrecompileSet
{
    let metadata = StackSubstateMetadata::new(
        gas_limit,
        config,
    );

    let state = MemoryStackState::new(
        metadata,
        backend,
    );

    StackExecutor::new_with_precompiles(
        state,
        config,
        precompiles,
    )
}


