# SharedTools
https://medium.com/@chimera_defi/sharedtools-c2fe8e49ba9b


# Howto:

Contracts here are used in https://github.com/chimera-defi/sharedtools-factory-ui
To draw the UIs at factory.sharedtools.org. 

You can deploy a contract, or contract factory from here.  The attached deploy utils will verify the contract for you.   
Additionally it will output a JSON that can be used in the factory-ui repo.  
Add the JSON to the user-interfaces-<network>.json or factories-network.json in `/utils` in the factory ui repo to list it.  

Additionally this repo has a toFactory.js script that can be modified to quickly create a scaffold for a contract factory from a base contract.  

# Metis notes

Farming contracts rely on solidity 0.8.0+ for overflow checking and are not safe for production use.  

VoteEscrowFactory was succesfully deployed. 
Had to tweak it a good amount to deal with no native ETH token errors from OVM, and going over the contract limit.  
Also had to remove any contracts that wouldnt compile. Wonder if there's a OVM variant of OZ.  

Created an OZ fork for metis 
https://github.com/chimera-defi/openzeppelin-contracts/pull/1

```
npm i --save @openzeppelin/contracts-metis@git+https://github.com/chimera-defi/openzeppelin-contracts-ovm#chimera-defi-metis

or add 
    "@openzeppelin/contracts-metis": "git://github.com/chimera-defi/openzeppelin-contracts#chimera-defi-metis",

to package.json and install

import as so:
import "@openzeppelin/contracts-metis/contracts/token/ERC20/IERC20.sol";

```
# Template base

Factory contracts for SharedTools. 
Features:
- Voting Escrow Contract 
- Factory for above
- Funddistributor contract
- MAsterchef contract
- Farming factory which launches the 2 above
- Clone factory, allowing clone proxies to be deployed saving gas on gas intensive networks like mainnet 

# Deploy

Add `--network <wanted network>` 
```
 npx hardhat run --network goerli deploy/deployFarmingFactory.js 

 npx hardhat run --network goerli deploy/deployVoteEscrowFactory.js 
 ```

# OLD
# Quickstart and developer notes

- Based on and following env best practices from https://github.com/paulrberg/solidity-template
- Following power user patterns from https://github.com/boringcrypto/dictator-dao
- Pre-run checks:

```
npm run-script prettier
npm run-script lint:sol
npx hardhat compile
```

- To deploy
```
npx hardhat run --network goerli deploy/deploy_common_1.js 
```

# Motivation
- Abstract away as much of deployment script functionality as possible to allow the dev to focus on the contracts
- Inherit as much stuff as possible to easily add new networks
- Powerful descriptive deploys 
- that track total expenditure for reimbursements
- Verify contracts on etherscan
- Output steps done
- Allow declarative syntax for full system state setup including things like token distributions and multisig ownership transfers
- Steps output can be easily turned into a readme for users pointing to contracts with links and description of everything done  

Most of this is based on my experience setting up new contracts for SharedStake.  Do with it what you will.  
# Errors

A note on errors
To reduce bytecode size and gas costs, error strings are shortened following UNIv3 as an example.  
The template is: {origin contract}:reason  
Common reasons:

```
CBL0 - contract balance will be less than 0 after this operation
VL0 - Value less than or equal to 0 and needs to be greater than 0
VLC - Value less than cap or check amount
AGC - Amount greater than cap or some stored value or requirement
NA - No Access / Not allowed
AE - Already exists
0AD - 0 address
```
