# Chainlink Price Oracle

[![CI](https://github.com/mimic-fi/chainlink-price-oracle/actions/workflows/ci.yml/badge.svg)](https://github.com/mimic-fi/chainlink-price-oracle/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/@mimic-fi/chainlink-price-oracle/latest.svg)](https://www.npmjs.com/package/@mimic-fi/v1-chainlink-price-oracle/v/latest)

This repository contains an implementation of the Vault's [PriceOracle](https://github.com/mimic-fi/core/blob/master/packages/vault/contracts/interfaces/IPriceOracle.sol).
The `PriceOracle` is part of the core architecture and is in charge of providing an interface to rate a token based on another token to the Vault.
This can be achieved using any type of on-chain oracle, then this repo provides a simple implementation using Chainlink V3.

## Deployment

In order to deploy this smart contract locally you can simply do:

```ts
import { deploy } from '@mimic-fi/v1-helpers'

const tokens = [...]
const priceFeeds = [...]
const oracle = await deploy('@mimic-fi/v1-chainlink-price-oracle/artifacts/contracts/ChainlinkPriceOracle.sol/ChainlinkPriceOracle', [tokens, priceFeeds])
```

## Development

In order to use a `PriceOracle` you can simply do:

```solidity
import '@mimic-fi/v1-vault/contracts/interfaces/IPriceOracle.sol';

contract MyContract {
  IPriceOracle connector;

  function getTokenPrice(address token, address base) external returns (uint256)  {
    return oracle.getTokenPrice(token, base);
  }
}
```
