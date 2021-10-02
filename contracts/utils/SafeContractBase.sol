// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract SafeContractBase is AccessControlEnumerable, Pausable, ReentrancyGuard {
    using Address for address;

    constructor() {}

    /* solhint-disable */
    // Inspired by alchemix smart contract gaurd at https://github.com/alchemix-finance/alchemix-protocol/blob/master/contracts/Alchemist.sol#L680
    /// @dev Checks that caller is a EOA.
    ///
    /// This is used to prevent contracts from interacting.
    modifier noContractAllowed() {
        require(!address(_msgSender()).isContract() && _msgSender() == tx.origin, "USCB:NC");
        _;
    }

    // uint256[50] private ______gap;
    /* solhint-enable */
}
