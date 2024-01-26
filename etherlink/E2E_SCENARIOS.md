# E2E Real World scenarios

Milestone: https://gitlab.com/tezos/tezos/-/milestones/310#end-to-end-real-world-scenarios
Repo: https://github.com/trilitech/live-testing-protocols/tree/main

## Scenario 1: ERC-20 (token)

## Scenario 2: ERC-721 (NFT)

## Scenario 3: ERC-1967 (transparent proxy pattern)

## Scenario 4: conventional NFT dApp

Basic scenario of an NFT dApp using Etherlink as blockchain layer.

The code for the scenario can be found in [here](https://github.com/Camillebzd/nft_marketplace_alchemy_rtw3_7) and the live website can be be found [here](https://nft-marketplace-alchemy-rtw3-7-etherlink-nightly.vercel.app/).

### Actions:

1. Users can connect their Metamask wallet to see the list of the NFTs and interact with the dApp
   * Basic connection between the Metamask and the dApp
   * Add and/or switch the good network setup for the dApp (Nightly or Etherlink ghostnet)
2. Users can create a token and list it on the dApp
   * The token is created with the good URL (the good image, name, price and description)
   * The owner can see on his profile and on the explorer the NFT
3. Users can buy listed tokens on the dApp
   * Select a token listed on the Marketplace and make a transaction to buy it
   * The new owner can see it on his profile and on the explorer

This actions need to be done manually directly on the dApp either locally or on the [live website](https://nft-marketplace-alchemy-rtw3-7-etherlink-nightly.vercel.app).

### Testing

I recommend testing the dApp directly on the [live website](https://nft-marketplace-alchemy-rtw3-7-etherlink-nightly.vercel.app). Otherwise, you will need to follow the instructions to run it locally like described [here](https://github.com/Camillebzd/nft_marketplace_alchemy_rtw3_7?tab=readme-ov-file#setup). :warning: If you run it locally, you will need to create a [Pinata](https://www.pinata.cloud/) account and an API key.


## Scenario 5: the Uniswap v2 DeFi protocol

## Scenario 6: interactions with Foundry

## Scenario 7: interactions with Hardhat

## Scenario 8: interactions with Remix

## Scenario 9: interactions with MetaMask

## Scenario 10: interactions with ThirdWeb
