// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract PaymentSplitterFactory {
    event PaymentSplitterCreated(address indexed addr);

    constructor() {}

    function createPaymentSplitter(address[] memory payees, uint256[] memory shares_) external returns (address res) {
        res = address(new PaymentSplitter(payees, shares_));
        emit PaymentSplitterCreated(res);
        return res;
    }
}
