const randomness = artifacts.require("Randomness");
const governance = artifacts.require("Governance");

module.exports = async function (deployer, network, accounts) {
  // const userAddress = accounts[3];
  var governanceContract = await governance.deployed();
  let args = [
    // FIXME CONTRACT ADDRESS
    governanceContract.address,
    "$DEPLOYMENT1",
    "$DEPLOYMENT0",
  ];
  await deployer.deploy(randomness, ...args);
};
