
   
// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
interface IIronSwapInit {

    function initialize(
        address[] memory _coins,
        uint8[] memory _decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _A,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee,
        address _feeDistributor
    ) external;
}