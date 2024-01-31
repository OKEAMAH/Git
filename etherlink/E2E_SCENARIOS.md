# E2E Real World scenarios

Milestone: https://gitlab.com/tezos/tezos/-/milestones/310#end-to-end-real-world-scenarios
Repo: https://github.com/trilitech/live-testing-protocols/tree/main

## Scenario 1: ERC-20 (token)

## Scenario 2: ERC-721 (NFT)

## Scenario 3: ERC-1967 (transparent proxy pattern)

## Scenario 4: conventional NFT dApp

## Scenario 5: the Uniswap v2 DeFi protocol

## Scenario 6: interactions with Foundry

Basic scenario using a simple Counter contract to test the deployment and interaction between Foundry and Etherlink.

The code for the scenario can be found in [Counter.sol](https://github.com/trilitech/development-tools-compatibility-etherlink/blob/main/foundry/src/Counter.sol).

### Actions:

1. User can deploy the Counter
   * The contract is deployed on Etherlink
   * User can see the contract address and transaction hash
2. User can verify the Counter
   * User can verify the contract
   * User can see the contract verified on Blockscout
3. User can check the value in the Counter using `cast`
   * User can make a request to see the value in the Counter
4. User can increment the value in the Counter using `cast`
   * User can make a transaction to increment the value in the Counter by 1
5. User can set the value in the Counter using `cast`
   * User can make a transaction to set the value in the Counter

The code for the deployment can be found in [Counter.s.sol](https://github.com/trilitech/development-tools-compatibility-etherlink/blob/main/foundry/script/Counter.s.sol). For the rest of the actions, the tool will directly make the interactions with Etherlink via the cli.

### Testing

Follow [these instructions](https://github.com/trilitech/development-tools-compatibility-etherlink/tree/main/foundry#deploy-the-contract-and-run-some-tests-on-etherlink) to deploy and test the Actions with the tool.

The test should go through, even if the interaction actually fails because of some issues in Etherlink, not the scenario. (Fixing Etherlink would be the purpose of the next task.)

### Special note

As Etherlink do not support EIP-1559 for the moment, all the interactions using Foundry are runned with the `--legacy` flag.

## Scenario 7: interactions with Hardhat

## Scenario 8: interactions with Remix

## Scenario 9: interactions with MetaMask

## Scenario 10: interactions with ThirdWeb
