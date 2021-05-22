## Project Overview :page_facing_up:
[![Build Integration](https://github.com/PlasmNetwork/ZKRollups/actions/workflows/evm.yml/badge.svg)](https://github.com/PlasmNetwork/ZKRollups/actions/workflows/evm.yml)

### Diclaimer
As a first step, we use Matter Labs' ZK Rollups contracts. Regarding the contracts, all credits goes to Matter Labs. What makes this implementation unique is that we will make a ZK Rollups Substrate pallet.

### Introduction
We believe that ZK Rollup is the killer layer2 solution in the coming months and some of the top projects will use this technology to make DApps scalable.

ZK Rollup is valuable for Polkadot Parachain as described below.
1. Bringing vertical off-chain scalability without sacrificing on-chain data availability, security and privacy (×3-10 scalability).
1. Handling smart contracts on layer2.
1. Sharding plus Rollups will be the future. Polkadot has the sharding ish architecture but it doesn't have Rollups yet.
1. Some of the great Ethereum projects have already started using Rollups. If we could build Rollups on Substeate/Polkadot, we would help them build applications on Polkdot Parachain like Plasm Network.

### Integration Test on Substrate

#### Premise

| Software | Version |
| ------------- | ------------- |  
| docker-compose | 1.27.4 |  
| docker | 19.03.13 |  
| git | 2.24.1 |  
| yarn | 1.21.1 |  
| git | 14.15.4 |

And there is private key file `$HOME/.ssh/id_rsa`.

#### Test

Execute following command in this project root directory.
```
$ sh scripts/integration.sh
```
This script executes the following sequence.

1. Build Zk Rollup contracts [code](https://github.com/PlasmNetwork/ZKRollups/blob/master/scripts/integration.sh#L3)  
2. Build operator and prover containers [code](https://github.com/PlasmNetwork/ZKRollups/blob/master/scripts/build.sh#L30)  
3. Run substrate-based chain, operator, and prover, database containers [code](https://github.com/PlasmNetwork/ZKRollups/blob/master/scripts/integration.sh#L28)  
4. Run integration test container [code](https://github.com/PlasmNetwork/ZKRollups/blob/master/scripts/integration.sh#L29)  

#### Containers

| Name | Description |
| ------------- | ------------- |  
| substrate | substrate based chain |  
| test | integration test |  
| setup | setup Zksync env to deploy contract and fund coinbase account |  
| operator | sidechain operator |  
| prover | zk prover |  
| postgres | sidechain db |

#### yarn setup
`$ yarn setup` executes `test/src/setup-contract.ts` and `test/src/setup-wallet.ts`.  
- `test/src/setup-contract.ts`  
Deploy all Zk Rollup contracts to the substrate-based chain(substrate)
- `test/src/setup-wallet.ts`  
Fund some tokens to the tester wallet.

#### yarn integration
`$ yarn integration` executes [`zksync integration test`](https://github.com/ArtreeTechnologies/zksync/blob/master/core/tests/ts-tests/tests/main.test.ts).  
The `zksync integration test` tests
- Depositing ETH  
- Changing public key  
- Transfering ETH  
- Collecting transaction fee  
- Exiting ETH
