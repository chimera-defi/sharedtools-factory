// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "./MintableNFTSale.sol";
contract MintableNFTSaleERC20 is MintableNFTSale {
  using Address for address;

  address[] public validAssets;
  mapping(address => uint256) public assetsMapping;
  constructor(
        string memory _name,
        string memory _symbol,
        address _paymentsSplitter, // Payment splitter that payments are withdrawn to, can be just your address
        uint256 _price, // Price of each NFT in ETH, 1 ETH = 1e18 or 1 followed by 18 0s
        uint256 _maxSupply, // max supply of the nfts
        uint256 _maxPerMint, // max no. of nfts a user can mint in a single tx. also max they can mint into 1 wallet
        uint256 _premint, // no. of nfts to allow to be preminted while `premint` is unpaused
        uint256 _freemint, // no. of nfts to allow minting for free while minting is unpaused
        address[] memory admins // admins of the cntract, needs at least 1 address
    ) MintableNFTSale(
                _name,
                _symbol,
                _paymentsSplitter,
                _price,
                _maxSupply,
                _maxPerMint,
                _premint,
                _freemint,
                admins
      ) {}

      function setValidAssets(address[] memory _validAssets, uint256[] memory _costs) public onlyAdminOrGovernance {
        validAssets = _validAssets;
        for (uint256 i; i<validAssets.length; i++) {
          assetsMapping[validAssets[i]] = _costs[i];
        }
      }

      function _mintChecks(address to, uint256 num) internal {
        uint256 supply = totalSupply();
        require(supply + num <= MAX_SUPPLY, "AGC:MAX_SUPPLY");
        uint256 tokenCount = balanceOf(to);
        require(tokenCount + num <= MAX_PER_MINT, "AGC:MAX_PER_MINT"); // max n tokens per user
      }

      function _wrappedMint(address to, uint256 num) internal {
        _mintChecks(to, num);
        uint256 supply = totalSupply();

        for (uint256 i; i < num; i++) {
          _safeMint(to, supply+i);
        }
      }

      function free_mint() public virtual payable override whenMintNotPaused nonReentrant {
        require(freemint > 0, "VL0:freemint");
        uint256 tokenCount = balanceOf(msg.sender);
        require(tokenCount + 1 <= MAX_PER_MINT, "AGC:MAX_PER_MINT"); // max n free tokens per user

        freemint -= 1;
        _wrappedMint(msg.sender, 1);
        emit redeemedFreeMint(msg.sender);
      }

      function mint(uint256 num) public virtual payable override {
        require(false, "Wrong function");
      }

      // Same as minting but let me collect some dues
      function mint(address asset, uint256 amount, uint256 num) public virtual payable whenMintNotPaused nonReentrant {
        uint256 price = assetsMapping[asset];
        require(price > 0, "Invalid asset");
        require(amount >= price*num, "Price paid too low");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        _wrappedMint(msg.sender, num);
      }

      function withdrawAllToSplitter() external virtual override {
        for (uint256 i; i<validAssets.length; i++) {
          address asset = validAssets[i];
          uint256 bal = IERC20(asset).balanceOf(address(this));
          if (bal > 0) {
            IERC20(asset).transfer(paymentsSplitter, bal);
          }
        }
        uint256 _balance = address(this).balance;
        if(_balance > 0) {
          require(payable(paymentsSplitter).send(_balance), "FAIL");
        }
      }
}