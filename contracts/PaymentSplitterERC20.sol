// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentSplitterERC20 is PaymentSplitter {
    mapping(address => mapping(address => uint256)) private _releasedERC20;
    mapping(address => uint256) private _totalReleasedERC20;

    constructor(address[] memory payees, uint256[] memory shares_) payable PaymentSplitter(payees, shares_) {}

    function releaseERC20(address payable account, address token) public virtual {
        require(shares(account) > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = IERC20(token).balanceOf(address(this)) + _totalReleasedERC20[token];
        uint256 payment = (totalReceived * shares(account)) / totalShares() - _releasedERC20[account][token];

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _releasedERC20[account][token] = _releasedERC20[account][token] + payment;
        _totalReleasedERC20[token] = _totalReleasedERC20[token] + payment;

        IERC20(token).transfer(account, payment);
        emit PaymentReleased(account, payment);
    }
}
