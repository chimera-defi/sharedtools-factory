// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import {SafeContractBase} from "./SafeContractBase.sol";

// A contract to make it DRY'er to recreate safe ownership roles
contract OwnershipRolesTemplate is SafeContractBase {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");

    // ====== Modifiers for syntactic sugar =======

    modifier onlyBenefactor() {
        _checkOnlyBenefactor();
        _;
    }

    modifier onlyAdminOrGovernance() {
        _checkOnlyAdminOrGovernance();
        _;
    }

    function togglePause() public onlyAdminOrGovernance {
        require(
            hasRole(PAUSER_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(GOVERNANCE_ROLE, _msgSender()),
            "ORT:NA"
        );
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(BENEFICIARY_ROLE, _msgSender());
    }

    function _checkOnlyAdminOrGovernance() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(GOVERNANCE_ROLE, _msgSender()), "ORT:NA");
    }

    function _checkOnlyBenefactor() private view {
        require(hasRole(BENEFICIARY_ROLE, _msgSender()), "ORT:NA");
    }
}
