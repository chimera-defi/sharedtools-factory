// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
