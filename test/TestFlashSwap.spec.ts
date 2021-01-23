import chai, { expect } from "chai";
import { Contract } from "ethers";
import { MaxUint256 } from "ethers/constants";
import { BigNumber, bigNumberify, defaultAbiCoder, formatEther } from "ethers/utils";
import { solidity, MockProvider, createFixtureLoader, deployContract } from "ethereum-waffle";

import { expandTo18Decimals } from "./shared/utilities";
import { v2Fixture } from "./shared/fixtures";

import HibachiArbitrage from "../build/HibachiArbitrage.json";

chai.use(solidity);

const overrides = {
  gasLimit: 9999999,
  gasPrice: 0,
};

describe("TestFlashSwapArbitrage", () => {
  const provider = new MockProvider({
    hardfork: "istanbul",
    mnemonic: "horn horn horn horn horn horn horn horn horn horn horn horn",
    gasLimit: 9999999,
  });
  const [wallet] = provider.getWallets();
  const loadFixture = createFixtureLoader(provider, [wallet]);

  let WETH: Contract;
  let WETHPartner: Contract;
  let WETHExchangeV1: Contract;
  let WETHPair: Contract;
  let flashSwapExample: Contract;
  beforeEach(async function () {
    const fixture = await loadFixture(v2Fixture);

    WETH = fixture.WETH;
    WETHPartner = fixture.WETHPartner;
    WETHExchangeV1 = fixture.WETHExchangeV1;
    WETHPair = fixture.WETHPair;
    flashSwapExample = await deployContract(
      wallet,
      HibachiArbitrage,
      [fixture.factoryV2.address, fixture.factoryV1.address, fixture.router.address],
      overrides,
    );
  });
});
