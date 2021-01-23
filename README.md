# Hibachi Store

[🍣 SushiSwap Governance Preliminary Discussion and Proposal](https://forum.sushiswapclassic.org/t/hibachi-store-lottery-based-arbitrage-payouts-for-incentivizing-lps-and-volume/2020)

## Hibachi Store: Propposal for SushiSwap

Contract source code has not been published in its entirety!

## Developer Tools 🛠️

- [Truffle](https://trufflesuite.com/)
- [TypeChain](https://github.com/ethereum-ts/TypeChain)
- [Openzeppelin Contracts](https://openzeppelin.com/contracts/)

### Contracts

```
├── ArbitrageCalculation.sol
├── HibachiArbitrage.sol
├── Migrations.sol
├── Randomness.sol
├── interfaces
│   ├── LinkTokenInterface.sol
│   ├── hibachiStore.sol
│   └── kingroll.sol
├── libraries
│   ├── DSMath.sol
│   ├── UniswapV2Library.sol
│   └── UniswapV2OracleLibrary.sol
├── proxies
│   └── lendingProxy.sol
├── vendor
│   └── SafeMath.sol
└── vrf
    ├── LinkTokenReceiver.sol
    ├── VRF.sol
    ├── VRFConsumerBase.sol
    ├── VRFCoordinator.sol
    └── VRFRequestIDBase.sol
```

### Tests 🔮

```bash
$ yarn test
```

### Coverage 🧰

```bash
$ yarn coverage
```

### Deploying 🛫

Deploy to Kovan:

```bash
$ NETWORK=kovan yarn deploy
```

## Verifying Contract Code 🎛

```bash
$ NETWORK=rinkeby yarn run verify YourContractName
```

## License

SPDX-License-Identifier: GPL-3.0+
