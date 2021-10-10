// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "../PaymentSplitterERC20.sol";

contract PaymentSplitterERC20Factory {
    event PaymentSplitterCreated(address indexed addr);

    constructor() {}

    function createPaymentSplitterERC20(address[] memory payees, uint256[] memory shares_)
        external
        returns (address res)
    {
        res = address(new PaymentSplitterERC20(payees, shares_));
        emit PaymentSplitterCreated(res);
        return res;
    }
}
