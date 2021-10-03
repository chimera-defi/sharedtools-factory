
   
// only use this for testnets
// mainnet deploys are very brittle
let {DeployHelper} = require("./deploy_utils.js");
let fs = require("fs");

let files = fs.readdirSync("./contracts/");
factories = files.filter(f => f.match('Factory'));

async function main() {
  let dh = new DeployHelper();
  await dh.init();
  for (const file of factories) {
    let name = file.split(".")[0];
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
