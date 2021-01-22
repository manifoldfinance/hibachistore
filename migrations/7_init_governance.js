const randomness = artifacts.require("Randomness");
const hibachiStore = artifacts.require("HibachiStore");
const governance = artifacts.require("Governance");

module.exports = async function(deployer, network, accounts) {
    var governanceContract = await governance.deployed();
    var hibachiStoreContract = await hibachiStore.deployed();
    var randomnessContract = await randomness.deployed();

    await governanceContract.init(
        hibachiStoreContract.address,
        randomnessContract.address
    )
};
