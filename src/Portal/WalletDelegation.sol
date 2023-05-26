// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IPortal.sol";
import "../Manager/IManager.sol";

contract WalletDelegation {
    enum DelegationState {
        NONE,
        APPROVED,
        REVOKED
    }

    address immutable participatingInterface;
    IManager immutable manager;

    // Master address => delegated address => chain sequence ID
    mapping(address => mapping(address => uint256)) public approvals;
    mapping(address => mapping(address => uint256)) public revokations;

    event WalletApproved(address delegator, address delegatee, uint256 chainSequenceId);
    event WalletRevoked(address delegator, address delegatee, uint256 chainSequenceId);

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IManager(_manager);
    }

    function approve(address delegatee) external {
        if (approvals[msg.sender][delegatee] != 0) revert();
        approvals[msg.sender][delegatee] = IPortal(manager.portal()).sequenceEvent();
        emit WalletApproved(msg.sender, delegatee, approvals[msg.sender][delegatee]);
    }

    function revoke(address delegatee) external {
        if (approvals[msg.sender][delegatee] == 0) revert();
        if (revokations[msg.sender][delegatee] != 0) revert();
        revokations[msg.sender][delegatee] = IPortal(manager.portal()).sequenceEvent();
        emit WalletRevoked(msg.sender, delegatee, revokations[msg.sender][delegatee]);
    }
}
