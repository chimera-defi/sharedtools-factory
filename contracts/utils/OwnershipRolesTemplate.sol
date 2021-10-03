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

    function togglePause() public {
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

    // Will revoke self roles that are overpriviledged
    function grantGovernanceRoles(address _governance) public onlyAdminOrGovernance {
        grantRole(PAUSER_ROLE, _governance);
        grantRole(GOVERNANCE_ROLE, _governance);
        grantRole(DEFAULT_ADMIN_ROLE, _governance);

        // Allow adding other sentinels/watchers to pause
        _setRoleAdmin(PAUSER_ROLE, GOVERNANCE_ROLE);
        // Allow adding/changing the benefactor address
        _setRoleAdmin(BENEFICIARY_ROLE, GOVERNANCE_ROLE);
        // Gov should be able to change gov in case of multisig change
        _setRoleAdmin(GOVERNANCE_ROLE, GOVERNANCE_ROLE);
    }

    function transferOwnership(address _governance) external onlyAdminOrGovernance {
        grantGovernanceRoles(_governance);
        revokeRole(GOVERNANCE_ROLE, msg.sender);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _checkOnlyAdminOrGovernance() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(GOVERNANCE_ROLE, _msgSender()), "ORT:NA");
    }

    function _checkOnlyBenefactor() private view {
        require(hasRole(BENEFICIARY_ROLE, _msgSender()), "ORT:NA");
    }
}
