// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IRollup.sol";
import "../Portal/IPortal.sol";
import "../Manager/IManager.sol";
import "../StateUpdateLibrary.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * The Rollup contract accepts settlement data reports from validators.
 */
contract Rollup is IRollup {
    uint256 public epoch = 0;
    mapping(uint256 => bytes32) public proposedStateRoot;
    mapping(uint256 => bytes32) public confirmedStateRoot;

    error CALLER_NOT_VALIDATOR();
    error EMPTY_STATE_ROOT();
    error INVALID_PROOF_SETTLEMENT();
    error INPUTS_LENGTH_MISMATCH_SETTLEMENT();
    error INPUTS_HASH_MISMATCH_SETTLEMENT();
    error INPUT_PARAMS_MISMATCH_SETTLEMENT();
    error INVALID_REQUEST_SETTLEMENT();

    IManager internal immutable manager;
    address internal immutable participatingInterface;

    // For compatability with Tacen Alpha
    uint256 public lastSettlementIdProcessed = 1;
    uint256 public nextRequestId = 2;
    event ObligationsWritten(
        uint256 id,
        address requester,
        address token,
        uint256 cleared
    );

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IManager(_manager);
    }

    /**
     * Called by the validator to propose a state root.
     */
    function proposeStateRoot(
        bytes32 stateRoot
    ) external {
        if (!manager.isValidator(msg.sender)) revert CALLER_NOT_VALIDATOR();
        confirmedStateRoot[epoch] = stateRoot;
        epoch++;
    }

    /**
     * Called by anyone to complete a settlement.
     */
    function processSettlement(
        StateUpdateLibrary.SettlementAcknowledgement
            calldata _settlementAcknowledgement,
        uint256 _stateRootId,
        bytes32[] calldata _proof,
        StateUpdateLibrary.UTXO[] calldata _inputs
    ) external {
        bytes32 stateRoot = confirmedStateRoot[_stateRootId];
        if (stateRoot == 0) revert EMPTY_STATE_ROOT();

        bool valid = MerkleProof.verify(
            _proof,
            stateRoot,
            keccak256(abi.encode(_settlementAcknowledgement))
        );
        if (!valid) revert INVALID_PROOF_SETTLEMENT();

        if (_inputs.length != _settlementAcknowledgement.inputs.length)
            revert INPUTS_LENGTH_MISMATCH_SETTLEMENT();

        StateUpdateLibrary.SettlementRequest
            calldata settlementRequest = _settlementAcknowledgement
                .settlementRequest;
        if (
            settlementRequest.chainId != block.chainid ||
            settlementRequest.settlementId != lastSettlementIdProcessed + 1
        ) revert INVALID_REQUEST_SETTLEMENT();

        unchecked {
            for (uint i = 0; i < _inputs.length; i++) {
                StateUpdateLibrary.UTXO calldata input = _inputs[i];
                bytes32 hashedInput = keccak256(abi.encode(input));

                if (hashedInput != _settlementAcknowledgement.inputs[i])
                    revert INPUTS_HASH_MISMATCH_SETTLEMENT();

                if (
                    input.asset != settlementRequest.asset ||
                    input.trader != settlementRequest.trader
                ) revert INPUT_PARAMS_MISMATCH_SETTLEMENT();

                IPortal(manager.portal()).writeObligation(
                    _inputs[i].depositUtxo,
                    _inputs[i].trader,
                    _inputs[i].amount
                );
            }
            lastSettlementIdProcessed++;
        }
        emit ObligationsWritten(
            settlementRequest.settlementId,
            settlementRequest.trader,
            settlementRequest.asset,
            IPortal(manager.portal()).getAvailableBalance(
                settlementRequest.trader,
                settlementRequest.asset
            )
        );
    }

    function requestSettlement(
        address _token,
        address _trader
    ) external returns (uint256) {
        require(msg.sender == manager.portal(), "NOT_WALLET_SINGLETON");
        // settlementRequests[nextRequestId] = SettlementData(block.number, token, trader);
        unchecked {
            nextRequestId++;
            return nextRequestId - 1;
        }
    }
}
