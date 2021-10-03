
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-metis/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-metis/contracts/token/ERC20/SafeERC20.sol";

contract MetisNativeTokenHelper {
    using SafeERC20 for IERC20;

    using SafeMath for uint256;
    address public constant metis = 0x4200000000000000000000000000000000000006;
    IERC20 public constant token = IERC20(0x4200000000000000000000000000000000000006);

    constructor() {

    }

    function metisBalanceOf(address account) public view returns (uint256) {
      return token.balanceOf(account);
    }

    // replacement for require(msg.value >= PRICE * num, "err"); for eth

    function msgValueGT(uint256 amt, address sender) public {
      token.safeTransferFrom(sender, address(this), amt);
    }

    function transferTo(address to, uint256 amt) public {
      token.safeTransferFrom(address(this), to, amt);
    }
}