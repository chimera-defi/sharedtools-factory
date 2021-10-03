// SPDX-License-Identifier: UNLICENSED
// @unsupported: ovm
pragma solidity 0.6.12;
import "@chimera-defi/merkle-distributor/contracts/ERC721MerkleDistributor.sol";
import "@openzeppelin/contracts-metis/contracts/access/Ownable.sol";

contract ERC721MerkleDistributorFactory {
    event ERC721MerkleDistributorCreated(address indexed addr, string _name, string _symbol);

    constructor() public {}

    function createERC721MerkleDistributor(
        bytes32 merkleRoot_,
        uint8 _tokenURIVariability,
        string memory _name,
        string memory _symbol
    ) external returns (address res) {
        res = address(new ERC721MerkleDistributor(merkleRoot_, _tokenURIVariability, _name, _symbol));
        Ownable(res).transferOwnership(msg.sender);
        emit ERC721MerkleDistributorCreated(res, _name, _symbol);
        return res;
    }
}
