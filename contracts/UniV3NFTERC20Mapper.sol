// SPDX-License-Identifier: GPL-2.0-or-later

/**
UniV3NFTERC20Mapper

Given an Uni v3 pool nft -> generate ERC20 for locking the pos nft

Whereas G-uni pools use the `uniswapV3MintCallback` requiring the pool to be created via their contracts
This contract will let user created uni v3 pools be mapped to ERC20
Guni: https://etherscan.io/address/0xf517263181e468fa958050cd6abfb58a445772ce#code

 */
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-staker/contracts/libraries/NFTPositionInfo.sol';
import '@uniswap/v3-staker/contracts/interfaces/IUniswapV3Staker.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';


import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";


contract UniV3NFTERC20Mapper is IERC721Receiver {

    struct UserInfo {
        uint256 amount;
        int256 tokensMinted;
        uint256 tokenID;
        bool isStaked;
    }
    /// @notice Represents the deposit of a liquidity NFT
    struct Deposit {
        address owner;
        uint48 numberOfStakes;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public override deposits;

    /// @notice Represents a staked liquidity NFT
    struct Stake {
        uint160 secondsPerLiquidityInsideInitialX128;
        uint96 liquidityNoOverflow;
        uint128 liquidityIfOverflow;
    }

    // token id => address of user => user info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev stakes[tokenId][incentiveHash] => Stake
    mapping(uint256 => Stake) private _stakes;

    mapping(uint256 => address) public UNIv3ToERC20;
    mapping(string => address) public nameToERC20;



    /// @inheritdoc IUniswapV3Staker
    IUniswapV3Factory public immutable override factory;
    /// @inheritdoc IUniswapV3Staker
    INonfungiblePositionManager public immutable override nonfungiblePositionManager;
  
    /// @param _factory the Uniswap V3 factory
    /// @param _nonfungiblePositionManager the NFT position manager contract address
    /// @param _maxIncentiveStartLeadTime the max duration of an incentive in seconds
    /// @param _maxIncentiveDuration the max amount of seconds into the future the incentive startTime can be set
    constructor(
        IUniswapV3Factory _factory,
        INonfungiblePositionManager _nonfungiblePositionManager,
        uint256 _maxIncentiveStartLeadTime,
        uint256 _maxIncentiveDuration
    ) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        maxIncentiveStartLeadTime = _maxIncentiveStartLeadTime;
        maxIncentiveDuration = _maxIncentiveDuration;
    }

    function mintForUser(uint256 tokenID) external {
        _updateUserInfo(tokenID);
      UserInfo uinfo = userInfo[tokenID][msg.sender];
      Deposit userDeposit = deposits[tokenID][msg.sender];

      require(uinfo.isStaked, "Token is not staked");
      uint256 amountToMint = uinfo.amount - uinfo.tokensMinted;
      

        (IUniswapV3Pool pool, int24 tickLower, int24 tickUpper, uint128 liquidity) =
            NFTPositionInfo.getPositionInfo(factory, nonfungiblePositionManager, tokenId);

        require(liquidity > 0, 'UniswapV3Staker::stakeToken: cannot stake token with 0 liquidity');

        uinfo.tokensMinted += amountToMint;
        userInfo[tokenID][msg.sender] = uinfo;

        _getERC20(tokenID, pool).mint(msg.sender, amountToMint);
    }

    function burnForUser(uint256 tokenID) external {
        _updateUserInfo(tokenID);
      UserInfo uinfo = userInfo[tokenID][msg.sender];

        (IUniswapV3Pool pool, int24 tickLower, int24 tickUpper, uint128 liquidity) =
            NFTPositionInfo.getPositionInfo(factory, nonfungiblePositionManager, tokenId);
        
        IERC20 token = _getERC20(tokenID, pool)
        
        // .mint(msg.sender, amountToMint);

        uint256 tokensMinted = uinfo.tokensMinted;

        TransferHelper.safeTransferFrom(address(token), msg.sender, address(this), tokensMinted);
        token.burn(tokensMinted);
        uinfo.tokensMinted = 0;
        userInfo[tokenID][msg.sender] = uinfo;
    }

    /// @inheritdoc IUniswapV3Staker
    function unstakeToken(uint256 tokenId) external override {
        Deposit memory deposit = deposits[tokenId];
        deposits[tokenId].numberOfStakes--;
    }

    /// @inheritdoc IUniswapV3Staker
    function withdrawToken(
        uint256 tokenId,
        address to,
        bytes memory data
    ) external override {
        require(to != address(this), 'UniswapV3Staker::withdrawToken: cannot withdraw to staker');
        Deposit memory deposit = deposits[tokenId];
        require(deposit.numberOfStakes == 0, 'UniswapV3Staker::withdrawToken: cannot withdraw token while staked');
        require(deposit.owner == msg.sender, 'UniswapV3Staker::withdrawToken: only owner can withdraw token');

        delete deposits[tokenId];
        emit DepositTransferred(tokenId, deposit.owner, address(0));

        nonfungiblePositionManager.safeTransferFrom(address(this), to, tokenId, data);
    }

    function withdraw(uint256 tokenId) external {
        burnForUser(tokenId);
        unstakeToken(tokenId);
        withdrawToken(tokenId, msg.sender, '0x');

    }


    function _getERC20(uint256 tokenID, IUniswapV3Pool pool) internal returns (IERC20) {
        if (UNIv3ToERC20[tokenID] == address(0)) {
            string name = _getTokenName(pool);
            if (nameToERC20[name] == address(0)) {
                nameToERC20[name] = address(new(ERC20PresetMinterPauser(name, name)));
            }
            UNIv3ToERC20[tokenID] = nameToERC20[name];
        }
        return UNIv3ToERC20[tokenID];
    }

    /// @notice Upon receiving a Uniswap V3 ERC721, creates the token deposit setting owner to `from`. Also stakes token
    /// in one or more incentives if properly formatted `data` has a length > 0.
    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(nonfungiblePositionManager),
            'UniswapV3Staker::onERC721Received: not a univ3 nft'
        );

        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = nonfungiblePositionManager.positions(tokenId);

        deposits[tokenId] = Deposit({owner: from, numberOfStakes: 0, tickLower: tickLower, tickUpper: tickUpper});
        emit DepositTransferred(tokenId, address(0), from);

        _stakeToken(tokenId);
        mintForUser(tokenId)
        // if (data.length > 0) {
        //     if (data.length == 160) {
        //         _stakeToken(abi.decode(data, (IncentiveKey)), tokenId);
        //     } else {
        //         IncentiveKey[] memory keys = abi.decode(data, (IncentiveKey[]));
        //         for (uint256 i = 0; i < keys.length; i++) {
        //             _stakeToken(keys[i], tokenId);
        //         }
        //     }
        // }
        return this.onERC721Received.selector;
    }

    function _updateUserInfo(uint256 tokenId) private {

        (IUniswapV3Pool pool, int24 tickLower, int24 tickUpper, uint128 liquidity) =
            NFTPositionInfo.getPositionInfo(factory, nonfungiblePositionManager, tokenId);
        require(liquidity > 0, 'UniswapV3Staker::stakeToken: cannot stake token with 0 liquidity');
        (, uint160 secondsPerLiquidityInsideX128, ) = pool.snapshotCumulativesInside(tickLower, tickUpper);

        if (liquidity >= type(uint96).max) {
            _stakes[tokenId] = Stake({
                secondsPerLiquidityInsideInitialX128: secondsPerLiquidityInsideX128,
                liquidityNoOverflow: type(uint96).max,
                liquidityIfOverflow: liquidity
            });
        } else {
            Stake storage stake = _stakes[tokenId];
            stake.secondsPerLiquidityInsideInitialX128 = secondsPerLiquidityInsideX128;
            stake.liquidityNoOverflow = uint96(liquidity);
        }

        uint256 tokensMinted = userInfo[tokenId][msg.sender].tokensMinted;

        userInfo[tokenId][msg.sender] = UserInfo({amount: _stakes[tokenId].secondsPerLiquidityInsideX128, tokensMinted: tokensMinted, tokenID: tokenId, isStaked: true});

    }

    /// @dev Stakes a deposited token without doing an ownership check
    function _stakeToken(uint256 tokenId) private {
        (IUniswapV3Pool pool, int24 tickLower, int24 tickUpper, uint128 liquidity) =
            NFTPositionInfo.getPositionInfo(factory, nonfungiblePositionManager, tokenId);
        require(liquidity > 0, 'UniswapV3Staker::stakeToken: cannot stake token with 0 liquidity');


        deposits[tokenId].numberOfStakes++;

        // (, uint160 secondsPerLiquidityInsideX128, ) = pool.snapshotCumulativesInside(tickLower, tickUpper);
        // _updateUserInfo(tokenId);
        // if (liquidity >= type(uint96).max) {
        //     _stakes[tokenId] = Stake({
        //         secondsPerLiquidityInsideInitialX128: secondsPerLiquidityInsideX128,
        //         liquidityNoOverflow: type(uint96).max,
        //         liquidityIfOverflow: liquidity
        //     });
        // } else {
        //     Stake storage stake = _stakes[tokenId];
        //     stake.secondsPerLiquidityInsideInitialX128 = secondsPerLiquidityInsideX128;
        //     stake.liquidityNoOverflow = uint96(liquidity);
        // }

        // uint256 tokensMinted = userInfo[tokenId][msg.sender].tokensMinted;

        // userInfo[tokenId][msg.sender] = UserInfo({amount: _stakes[tokenId].secondsPerLiquidityInsideX128, tokensMinted: tokensMinted, tokenID: tokenId, isStaked: true});

        emit TokenStaked(tokenId, liquidity);
    }

    function _getTokenName(IUniswapV3Pool pool) internal returns (string memory)
    {
        return getTokenName(pool.token0(), pool.token1());
    }

    function getTokenName(address token0, address token1)
        external
        view
        returns (string memory)
    {
        string memory symbol0 = IERC20Metadata(token0).symbol();
        string memory symbol1 = IERC20Metadata(token1).symbol();

        return _append("Uniswap v3", symbol0, "/", symbol1, " LP");
    }
}