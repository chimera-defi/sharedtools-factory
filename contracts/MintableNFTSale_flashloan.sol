// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "./MintableNFTSaleERC20.sol";
contract MintableNFTSale_flashloan is MintableNFTSaleERC20 {
  using Address for address;

  struct Info {
    uint256 amt;
    address asset;
  }
  mapping(uint256 => Info) public tokenIDToInfoMapping;

  uint256 public highScore;
  uint256 public topDegen;

  uint256 public minAmt;
  constructor(
        string memory _name,
        string memory _symbol,
        address _paymentsSplitter, // Payment splitter that payments are withdrawn to, can be just your address
        uint256 _price, // Price of each NFT in ETH, 1 ETH = 1e18 or 1 followed by 18 0s
        uint256 _maxSupply, // max supply of the nfts
        uint256 _maxPerMint, // max no. of nfts a user can mint in a single tx. also max they can mint into 1 wallet
        uint256 _premint, // no. of nfts to allow to be preminted while `premint` is unpaused
        uint256 _freemint, // no. of nfts to allow minting for free while minting is unpaused
        address[] memory admins, // admins of the cntract, needs at least 1 address
        uint256 _minAmt
    ) MintableNFTSaleERC20(
                _name,
                _symbol,
                _paymentsSplitter,
                _price,
                _maxSupply,
                _maxPerMint,
                _premint,
                _freemint,
                admins
      ) {
        minAmt = _minAmt;
      }

      function tokenURI(uint256 tokenId) override public view returns (string memory output) {
        Info memory info = tokenIDToInfoMapping[tokenId];

        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = string(abi.encodePacked(" Flash Loan User! ", " "));
        parts[2] = '</text><text x="10" y="160" class="base">';
        parts[3] = string(abi.encodePacked(info.asset, " "));
        parts[4] = '</text><text x="10" y="160" class="base">';
        parts[5] = string(abi.encodePacked(_uint2str(info.amt), " "));
        parts[6] = '</text></svg>';

        // The largest flash loaner gets a special King tag
        if (highScore <= info.amt) {
          parts[1] = string(abi.encodePacked(" Flash Loan King! ", " "));
        }

        output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
      }

      function _checkIsFlashloan(address asset, uint256 amount) internal {
        require(address(_msgSender()).isContract() && _msgSender() != tx.origin, "Only contracts!");
        require(assetsMapping[asset] > 0, "Invalid asset");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
      }

      function _flasher() internal returns (address) {
        return tx.origin;
      }

      function _flashmint(address asset, uint256 amount, uint256 fee) internal {
        _mintChecks(_flasher(), 1);
        uint256 transferAmt = amount > minAmt ? amount : minAmt;
        _checkIsFlashloan(asset, transferAmt);
        uint256 supply = totalSupply();
        _safeMint(_flasher(), supply);
        tokenIDToInfoMapping[supply] = Info({
          amt: amount,
          asset: asset
        });

        // Pay me my pittance if you want to be king mr big flash loan money bags
        if (highScore <= amount && fee > 0) {
          highScore = amount;
        }
        // Give the contract the money back
        IERC20(asset).transfer(msg.sender, transferAmt-fee);
      }

      function free_mint(address asset, uint256 amount) public virtual payable whenMintNotPaused nonReentrant {
        require(freemint > 0, "VL0:freemint");
        uint256 tokenCount = balanceOf(msg.sender);
        require(tokenCount + 1 <= MAX_PER_MINT, "AGC:MAX_PER_MINT"); // max n free tokens per user

        freemint -= 1;
        _flashmint(asset, amount, 0);
        emit redeemedFreeMint(msg.sender);
      }

      function mint(uint256 num) public virtual payable override {
        require(false, "Wrong function");
      }

      function free_mint() public virtual payable override {
        require(false, "Wrong function");
      }

      // Same as minting but let me collect some dues
      function mint(address asset, uint256 amount, uint256 num) public virtual override payable whenMintNotPaused nonReentrant {
        uint256 tokenCount = balanceOf(msg.sender);
        require(tokenCount + num <= MAX_PER_MINT, "AGC:MAX_PER_MINT"); // max n free tokens per user
        uint256 price = assetsMapping[asset];
        require(price > 0, "Invalid asset");
        require(amount >= price*num, "Price paid too low");

        for (uint256 i; i < num; i++) {
            _flashmint(asset, amount, assetsMapping[asset]);
        }
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

      function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}