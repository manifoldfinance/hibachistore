const randomness = artifacts.require("Randomness");
const hibachiStore = artifacts.require("HibachiStore");
const governance = artifacts.require("Governance");

module.exports = async function (deployer, network, accounts) {
  var governanceContract = await governance.deployed();
  var hibachiStoreContract = await hibachiStore.deployed();
  var randomnessContract = await randomness.deployed();

  await hibachiStoreContract.addStableCoin("0xb5e5d0f8c0cba267cd3d7035d6adc8eba7df7cdd", "1");

  await hibachiStoreContract.openNewDraw();
};
