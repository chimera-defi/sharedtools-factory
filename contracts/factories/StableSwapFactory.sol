// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "iron-swap/contracts/IronSwap.sol";
// import "iron-swap/contracts/IronSwapLib.sol";
// import "iron-swap/contracts/FeeDistributor.sol"; // you may choose to deploy it

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IIronSwapInit.sol";

interface IFeeDistributor {
    function initialize(address _target, address _swapRouter) external;
}

contract StableswapFactory is Ownable {
    address public libAddress;
    address public feeDistributor;
    address public ironSwapRouter;

    constructor(address _ironSwapRouter) {
        setParams(_ironSwapRouter);
    }

    function setParams(address _ironSwapRouter) public onlyOwner {
        ironSwapRouter = _ironSwapRouter;
    }

    /**
e.g. 

    [wellknown.addresses.usdc, wellknown.addresses.usdt, wellknown.addresses.dai], //_coins,
    [6, 6, 18], //token decimals
    'IRON Stableswap 3USD', // pool token name
    'IS3USD', //_pool_token
    800, // _A
    1e6, //_fee 0.01%
    5000000000, //_admin_fee 50%
    5e7, // withdrawal fee 0.4%
    feeDistributor.address
 */
    function deployStableSwap(
        address[] memory _coins,
        uint8[] memory _decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _A,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee
    ) external returns (address res) {
        res = address(new IronSwap());

        // fd = deployFeeDistributor(_feeBaseToken);

        IIronSwapInit(res).initialize(
            _coins,
            _decimals,
            lpTokenName,
            lpTokenSymbol,
            _A,
            _fee,
            _adminFee,
            _withdrawFee,
            msg.sender // update to a fee distributor or payment splitter post deploy
        );

        Ownable(res).transferOwnership(msg.sender);
        // Ownable(fd).transferOwnership(msg.sender);
    }
}
