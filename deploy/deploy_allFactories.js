// only use this for testnets
// mainnet deploys are very brittle
let {DeployHelper} = require("./deploy_utils.js");

let fs = require("fs");

let files = fs.readdirSync("./contracts/factories/");

async function main() {
  let dh = new DeployHelper();
  await dh.init();

  // Also deploy all underlying contracts
  // so we dont' need to manually verify them on etherscan
  await dh.deployContract("ERC20PresetFixedSupply", "ERC20PresetFixedSupply", ["test", "test", 10000, dh.address]);
  let erc20Address = dh.addressOf("ERC20PresetFixedSupply");
  await dh.deployContract("FundDistributor", "FundDistributor", [erc20Address]);
  await dh.deployContract("PaymentSplitter", "PaymentSplitter", [[dh.address], [100]]);
  await dh.deployContract("PaymentSplitterERC20", "PaymentSplitterERC20", [[dh.address], [100]]);

  await dh.deployContract("MasterChef", "MasterChef", [erc20Address, dh.addressOf("FundDistributor"), dh.address]);
  await dh.deployContract("MintableNFTSale", "MintableNFTSale", [
    "testNft",
    "tnft",
    dh.addressOf("PaymentSplitter"),
    100,
    100,
    1,
    1,
    1,
    [],
  ]);
  await dh.deployContract("VoteEscrow", "VoteEscrow", ["veTst", "vtst", dh.addressOf("ERC20PresetFixedSupply"), 1]);

  for (const file of files) {
    let name = file.split(".")[0];
    if (name == "StableSwapFactory") continue;
    await dh.deployContract(name, name);
  }
  await dh.postRun();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
