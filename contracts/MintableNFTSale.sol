// Based loosely on galaxyEggs
// https://etherscan.io/address/0xa08126f5e1ed91a635987071e6ff5eb2aeb67c48#code

/**
 * Generic Mintable NFT Sale contract
 * Create a collection with the following variables
 * - max supply - max number of nfts
 * - price - per nft
 * - Max items per mint
 * - pre mint - number of NFTs that can be preminted for free, by whitelisted users, or in a batch for admins e.g. for giveaways
 * - free mint - number of nfts to allow users to mint for free
 * Allow users to mint for a given price
 * Contract accumulates ETH from sales
 * Accumulated ETH can be withdrawn to a EOA or paymentSplitter to split gains across many users using withdrawAllToSplitter
 *
 * Admins can set the baseTokenURI before or after a drop
 * Setting the baseTokenURI after a drop, allows the contract to sell off NFTs with different rarities with the same price without cheating
 *
 * Advantages:
 - specify a price and change it later
 - create a limited supply collection, and add new items later
 - cheaper than rarible nft factory? 
 - add royalties on opensea and rarible later when the collection is imported
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

// import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-metis/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-metis/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-metis/contracts/math/SafeMath.sol";

// import "./utils/OwnershipRolesTemplate.sol";

import "./MetisNativeTokenHelper.sol";
import "./AddressMetis.sol";
import "@openzeppelin/contracts-metis/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-metis/contracts/utils/ReentrancyGuard.sol";

contract MintableNFTSale is ERC721, AccessControl, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    event MintPaused(address account);

    event MintUnpaused(address account);

    event PreMintPaused(address account);

    event PreMintUnpaused(address account);

    event setPreMintRole(address account);

    event redeemedPreMint(address account);

    event redeemedFreeMint(address account);

    uint256 public PRICE;
    uint256 public MAX_SUPPLY;
    uint256 public MAX_PER_MINT;

    uint256 public pre_mint_reserved;
    uint256 public freemint;

    mapping(address => bool) private _pre_sale_minters;

    bool public paused_mint = true;
    bool public paused_pre_mint = true;
    string private _baseTokenURI = "";

    // withdraw addresses
    address public paymentsSplitter;

    modifier whenMintNotPaused() {
        require(!paused_mint, "mint paused");
        _;
    }

    modifier whenPreMintNotPaused() {
        require(!paused_pre_mint, "premint paused");
        _;
    }

    modifier preMintAllowedAccount(address account) {
        require(is_pre_mint_allowed(account), "NA");
        _;
    }

    modifier onlyAdminOrGovernance() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
        _;
    }

    modifier noContractAllowed() {
        require(!Address.isContract(msg.sender), "NA");
        _;
    }

    // constructor() {}

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
    ) ERC721(_name, _symbol) {
        paymentsSplitter = _paymentsSplitter;
        PRICE = _price;
        MAX_SUPPLY = _maxSupply;
        MAX_PER_MINT = _maxPerMint;
        pre_mint_reserved = _premint;
        freemint = _freemint;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function updateParams(uint256[] memory numericParams, address _paymentsSplitter) external onlyAdminOrGovernance {
        PRICE = numericParams[0];
        MAX_SUPPLY = numericParams[1];
        MAX_PER_MINT = numericParams[2];
        pre_mint_reserved = numericParams[3];
        freemint = numericParams[4];
        paymentsSplitter = _paymentsSplitter;
    }

    function transferOwnership(address newOwner) external onlyAdminOrGovernance {
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    fallback() external payable {}

    receive() external payable {}

    function mint(uint256 num) public payable nonReentrant whenMintNotPaused noContractAllowed {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);
        require(num <= MAX_PER_MINT, "AGC:MAX_PER_MINT");
        require(tokenCount.add(num) <= MAX_PER_MINT, "AGC:MAX_PER_MINT"); // max n tokens per user
        require(supply.add(num) <= MAX_SUPPLY, "AGC:MAX_SUPPLY");
        MetisNativeTokenHelper.msgValueGT(PRICE.mul(num), msg.sender);
            // "VLC:price*num"

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function pre_mint()
        public
        payable
        whenPreMintNotPaused
        preMintAllowedAccount(msg.sender)
        noContractAllowed
        nonReentrant
    {
        require(pre_mint_reserved > 0, "VL0:pre_mint_reserved");
    //     require(
    // MetisNativeTokenHelper.msgValueGT(PRICE, msg.sender),
    // "VLC:price");
        MetisNativeTokenHelper.msgValueGT(PRICE, msg.sender);

        _pre_sale_minters[msg.sender] = false;
        pre_mint_reserved -= 1;
        uint256 supply = totalSupply();
        _safeMint(msg.sender, supply);
        emit redeemedPreMint(msg.sender);
    }

    function free_mint() public payable whenMintNotPaused noContractAllowed nonReentrant {
        require(freemint > 0, "VL0:freemint");
        freemint -= 1;
        uint256 supply = totalSupply();
        _safeMint(msg.sender, supply);
        emit redeemedFreeMint(msg.sender);
    }

    // For admins/governance
    // Allow preminting a batch for compensation or giveaways
    function pre_mint_batch(uint256 num)
        public
        payable
        whenPreMintNotPaused
        preMintAllowedAccount(msg.sender)
        onlyAdminOrGovernance
        noContractAllowed
        nonReentrant
    {
        require(pre_mint_reserved > 0, "VL0:pre_mint_reserved");
        uint256 supply = totalSupply();
        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
        pre_mint_reserved -= num;
        emit redeemedPreMint(msg.sender);
    }

    function pauseMint() public onlyAdminOrGovernance {
        paused_mint = true;
        emit MintPaused(msg.sender);
    }

    function unpauseMint() public onlyAdminOrGovernance {
        paused_mint = false;
        emit MintUnpaused(msg.sender);
    }

    function pausePreMint() public onlyAdminOrGovernance {
        paused_pre_mint = true;
        emit PreMintPaused(msg.sender);
    }

    function unpausePreMint() public onlyAdminOrGovernance {
        paused_pre_mint = false;
        emit PreMintUnpaused(msg.sender);
    }

    function setPreMintRoleBatch(address[] calldata _addresses) external onlyAdminOrGovernance {
        for (uint256 i; i < _addresses.length; i++) {
            _pre_sale_minters[_addresses[i]] = true;
            emit setPreMintRole(_addresses[i]);
        }
    }

    function setBaseURI(string memory baseURI) public onlyAdminOrGovernance {
        _baseTokenURI = baseURI;
    }

    function withdrawAllToSplitter() external {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "VLC");
        require(payable(paymentsSplitter).send(_balance), "FAIL");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "INVALID");

        string memory baseURI = getBaseURI();
        string memory json = ".json";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     override(ERC721, AccessControl)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }

    function is_pre_mint_allowed(address account) public view returns (bool) {
        return _pre_sale_minters[account];
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}