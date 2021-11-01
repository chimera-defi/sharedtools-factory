const constants = require("../constants.js");

async function main() {
  let {DeployHelper} = require("./deploy_utils.js");
  let dh = new DeployHelper();
  await dh.init();

  // Deploy a smurf contract to allow auto etherscan verification in the future

  // Args:    
  // string memory _name, string memory _symbol, address _tokenA, address _tokenB, uint256 _orderBlockInterval

  await dh.deployContract("TWAMM", "TWAMM", [
    "test1",
    "tst1",
    dh.addressOf(0),
    dh.addressOf(0),
    10 // avg is 14 sec/block on ETH 
  ]);
  await dh.deployContract("FrankiesTWAMMFactory", "FrankiesTWAMMFactory");
  await dh.postRun();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
