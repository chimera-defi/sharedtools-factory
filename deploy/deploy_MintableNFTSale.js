


async function main() {
  let {DeployHelper} = require("./deploy_utils.js");
  let dh = new DeployHelper();
  await dh.init();
  await dh.deployContract("MintableNFTSale", "MintableNFTSale", [
    "testNft",
    "tnft",
    dh.address,
    100,
    100,
    1,
    1,
    1,
    [],
  ]);
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
