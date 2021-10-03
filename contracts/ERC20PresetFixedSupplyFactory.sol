// SPDX-License-Identifier: UNLICENSED
// @unsupported: ovm
pragma solidity 0.7.6;
import "@openzeppelin/contracts-metis/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts-metis/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts-metis/contracts/access/Ownable.sol";


contract ERC20PresetFixedSupply is ERC20Capped {
  constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner) public ERC20(name, symbol) ERC20Capped(initialSupply) {
        _mint(owner, initialSupply);
    }
}

contract ERC20PresetFixedSupplyFactory {
    event ERC20PresetFixedSupplyCreated(address indexed addr);

    constructor() {}

    function createERC20PresetFixedSupply(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) external returns (address res) {
        res = address(new ERC20PresetFixedSupply(name, symbol, initialSupply, owner));
        emit ERC20PresetFixedSupplyCreated(res);
        return res;
    }
}
