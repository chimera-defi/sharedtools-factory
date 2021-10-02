// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
import "@chimera-defi/merkle-distributor/contracts/ERC20MerkleDistributorWithClawback.sol";
import "@openzeppelin/contracts3/access/Ownable.sol";

contract ERC20MerkleDistributorWithClawbackFactory {
    event ERC20MerkleDistributorWithClawbackCreated(address indexed addr);

    constructor() public {}

    function createERC20MerkleDistributorWithClawback(
        address token_,
        bytes32 merkleRoot_,
        uint256 durationDays_
    ) external returns (address res) {
        res = address(new ERC20MerkleDistributorWithClawback(token_, merkleRoot_, durationDays_));
        Ownable(res).transferOwnership(msg.sender);
        emit ERC20MerkleDistributorWithClawbackCreated(res);
        return res;
    }
}
