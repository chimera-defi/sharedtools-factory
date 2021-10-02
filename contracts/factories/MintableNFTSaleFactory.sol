// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "../MintableNFTSale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintableNFTSaleFactory {
    event MintableNFTSaleCreated(address indexed addr, string name, string indexed symbol);

    constructor() {}

    function createMintableNFTSale(
        string memory _name,
        string memory _symbol,
        address _paymentsSplitter,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _maxPerMint,
        uint256 _premint,
        uint256 _freemint,
        address[] memory admins
    ) external returns (address res) {
        res = address(
            new MintableNFTSale(
                _name,
                _symbol,
                _paymentsSplitter,
                _price,
                _maxSupply,
                _maxPerMint,
                _premint,
                _freemint,
                admins
            )
        );
        Ownable(res).transferOwnership(msg.sender);
        emit MintableNFTSaleCreated(res, _name, _symbol);
        return res;
    }
}
