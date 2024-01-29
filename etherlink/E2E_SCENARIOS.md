# E2E Real World scenarios

Milestone: https://gitlab.com/tezos/tezos/-/milestones/310#end-to-end-real-world-scenarios
Repo: https://github.com/trilitech/live-testing-protocols/tree/main

## Scenario 1: ERC-20 (token)

## Scenario 2: ERC-721 (NFT)

## Scenario 3: ERC-1967 (transparent proxy pattern)

## Scenario 4: conventional NFT dApp

## Scenario 5: the Uniswap v2 DeFi protocol

## Scenario 6: interactions with Foundry

## Scenario 7: interactions with Hardhat

## Scenario 8: interactions with Remix

Basic scenario using a simple Counter contract to test the deployment and interaction between Remix and Etherlink.

The code for the scenario can be found in [Counter.sol](https://github.com/trilitech/development-tools-compatibility-etherlink/blob/main/remix/Counter.sol).

### Actions:
1. User can deploy the Counter
   * The contract is deployed on Etherlink
   * User can see the contract address
2. User can check the value in the Counter
   * User can make a request to see the value in the Counter
3. User can increment the value in the Counter
   * User can make a transaction to increment the value in the Counter by 1
4. User can set the value in the Counter
   * User can make a transaction to set the value in the Counter

There is no code for the Actions as Remix is a graphical IDE, everything can be done manually on it.

### Manually testing the MR

Follow [these instructions](https://github.com/trilitech/development-tools-compatibility-etherlink/blob/main/remix/README.md#remix) to deploy and test the Actions with the tool.

### Special note

You also realize some tests with MetaMask tool because you need it to link Remix with Etherlink.

## Scenario 9: interactions with MetaMask

## Scenario 10: interactions with ThirdWeb
