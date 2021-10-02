// only use this for testnets
// mainnet deploys are very brittle
// let {deployUsingClass} = require("./deploy_utils.js");
let {DeployHelper} = require("./deploy_utils.js");

let fs = require("fs");
let files = fs.readdirSync("./contracts/factories/");

async function main() {
  let dh = new DeployHelper();
  await dh.init();
  for (const file of files) {
    let name = file.split(".")[0];
    console.log(`Deploy attempt for ${name}`)
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
