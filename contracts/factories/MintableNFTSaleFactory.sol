// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "../MintableNFTSale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintableNFTSaleFactory {
    event MintableNFTSaleCreated(address indexed addr, string name, string indexed symbol);

    constructor() {}

    /**
    See below for explanation of arguments:
    _name -> name of the nft
    _symbol -> text symbol of the nft
    address _paymentsSplitter, // Payment splitter that payments are withdrawn to, can be just your address
    uint256 _price, // Price of each NFT in ETH, 1 ETH = 1e18 or 1 followed by 18 0s
    uint256 _maxSupply, // max supply of the nfts
    uint256 _maxPerMint, // max no. of nfts a user can mint in a single tx. also max they can mint into 1 wallet
    uint256 _premint, // no. of nfts to allow to be preminted while `premint` is unpaused
    uint256 _freemint, // no. of nfts to allow minting for free while minting is unpaused
    address[] memory admins // admins of the cntract, needs at least 1 address
    */
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
