const fs = require("fs");

path = "node_modules/@chimera-defi/merkle-distributor/contracts/ERC20MerkleDistributorWithClawback.sol";
f = fs.readFileSync(path, "utf8");
contract_name = f.match(/contract\s(\w+)/gi)[0].split(" ")[1];

f2 = f.split("\n").join(" ");
cargs = f2.match(/constructor\(\s*(.*?)\s*\)/gi);
cargs = cargs[0]
  .replace("constructor(", "")
  .replace(")", "")
  .split(",")
  .map(s => s.trim());

args = cargs.map(s => s.split(" ").pop()).join(", ");
argsWithType = cargs.join(", ");

res = `
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "${path}";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ${contract_name}Factory {
  event ${contract_name}Created(
    address indexed addr
  );

  constructor() {}

  function create${contract_name}(
    ${argsWithType}
  ) external returns (address res) {
    res = address(new ${contract_name}(${args}));
    Ownable(res).transferOwnership(msg.sender);
    emit ${contract_name}Created(res);
    return res;
  }
}
`;

console.log(res);
