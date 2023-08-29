// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "./IProcessingChainManager.sol";
import "../../util/Id.sol";

contract WalletDelegation {
    using IdLib for Id;

    enum DelegationState {
        NONE,
        APPROVED,
        REVOKED
    }

    address immutable participatingInterface;
    IProcessingChainManager immutable manager;
    Id public chainSequenceId = ID_ONE;

    // Master address => delegated address => chain sequence ID
    mapping(address => mapping(address => Id)) public approvals;
    mapping(address => mapping(address => Id)) public revokations;

    event WalletApproved(address delegator, address delegatee, Id chainSequenceId);
    event WalletRevoked(address delegator, address delegatee, Id chainSequenceId);

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IProcessingChainManager(_manager);
    }

    function approve(address delegatee) external {
        if (approvals[msg.sender][delegatee] != ID_ZERO) revert();
        approvals[msg.sender][delegatee] = chainSequenceId;
        emit WalletApproved(msg.sender, delegatee, approvals[msg.sender][delegatee]);
        chainSequenceId = chainSequenceId.increment();
    }

    function revoke(address delegatee) external {
        if (approvals[msg.sender][delegatee] == ID_ZERO) revert();
        if (revokations[msg.sender][delegatee] != ID_ZERO) revert();
        revokations[msg.sender][delegatee] = chainSequenceId;
        emit WalletRevoked(msg.sender, delegatee, revokations[msg.sender][delegatee]);
        chainSequenceId = chainSequenceId.increment();
    }
}
