// // async function main() {
// //   let {DeployHelper} = require("./deploy_utils.js");
// //   let dh = new DeployHelper();
// //   await dh.init();
// //   await dh.deployContract("IronSwapLib", "IronSwapLib");
// //   await dh.deployContract("FeeDistributor", "FeeDistributor");
// //   await dh.deployContract("IronSwapRouter", "IronSwapRouter");

// //   await dh.deployContract("StableswapFactory", "StableswapFactory", [dh.addressOf("IronSwapRouter")]);

// //   await dh.postRun();
// // }

// // // We recommend this pattern to be able to use async/await everywhere
// // // and properly handle errors.
// // main()
// //   .then(() => process.exit(0))
// //   .catch(error => {
// //     console.error(error);
// //     process.exit(1);
// //   });
//   let {DeployHelper} = require("../deploy_utils.js");

//   const DeployFunction = async ({deployments, getNamedAccounts, wellknown}) => {
//     const {deploy, execute, get} = deployments;
//     let dh = new DeployHelper();
    
//     await dh.init();
//     creator = dh.address;

//     await dh.deployContract("IronSwapLib", "IronSwapLib");
//     await dh.deployContract("FeeDistributor", "FeeDistributor");
//     await dh.deployContract("IronSwapRouter", "IronSwapRouter");
    
//     const stableSwapLib = dh.addressOf('IronSwapLib');
//     const stableSwapRouter = dh.addressOf('IronSwapRouter');

//   const pool = await deploy('StableswapFactory', {
//     contract: 'StableswapFactory',
//     from: creator,
//     log: true,
//     args: [stableSwapRouter.address],
//     libraries: {
//       IronSwapLib: stableSwapLib.address,
//     },
//   });

//   }


// // export default func;

// // func.skip = async ({network}) => {
// //   return network.name != 'matic';
// // };

// // (async () => {
// //   DeployFunction
// // })();
// module.exports = DeployFunction;
// module.exports.tags = ['swap'];



let { DeployHelper } = require("../deploy_utils.js");

const DeployFunction = async ({ deployments, getNamedAccounts, wellknown }) => {
  const { deploy, execute, get } = deployments;
  let dh = new DeployHelper();

  await dh.init();
  creator = dh.address;

  await dh.deployContract("IronSwapLib", "IronSwapLib");
  await dh.deployContract("FeeDistributor", "FeeDistributor");
  await dh.deployContract("IronSwapRouter", "IronSwapRouter");
  
  const stableSwapLib = dh.addressOf('IronSwapLib');
  const stableSwapRouter = dh.addressOf('IronSwapRouter');

  const pool = await deploy('StableswapFactory', {
    contract: 'StableswapFactory',
    from: creator,
    log: true,
    args: [stableSwapRouter],
    libraries: {
      IronSwapLib: stableSwapLib,
    },
  });

  console.log(pool)

  dh.addContract("StableswapFactory", "StableswapFactory", pool.address, pool.args)
  await dh.postRun();

}

module.exports = DeployFunction;
module.exports.tags = ['swap'];
