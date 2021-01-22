const kingrollSwap = artifacts.require("KingRoll");
const governance = artifacts.require("Governance");

module.exports = async function (deployer, network, accounts) {
  var governanceContract = await governance.deployed();
  let args = [
    governanceContract.address,
    // TODO - SUSHISWAP
    "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a", //Uniswap v2 router
    "0xB5E5D0F8C0cbA267CD3D7035d6AdC8eBA7Df7Cdd", // compound Dai
  ];
  await deployer.deploy(kingrollSwap, ...args);
};
