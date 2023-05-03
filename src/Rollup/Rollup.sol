// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IRollup.sol";
import "../Portal/IPortal.sol";
import "../Manager/IManager.sol";
import "../StateUpdateLibrary.sol";
import "../util/Id.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * The Rollup contract accepts settlement data reports from validators.
 */
contract Rollup is IRollup {
    using IdLib for Id;

    Id public epoch = ID_ZERO;
    mapping(Id => bytes32) public proposedStateRoot;
    mapping(Id => bytes32) public confirmedStateRoot;

    error CALLER_NOT_VALIDATOR();
    error EMPTY_STATE_ROOT();
    error INVALID_PROOF_SETTLEMENT();
    error INVALID_STATE_UPDATE_SETTLEMENT();
    error INPUTS_LENGTH_MISMATCH_SETTLEMENT();
    error INPUTS_HASH_MISMATCH_SETTLEMENT();
    error INPUT_PARAMS_MISMATCH_SETTLEMENT();
    error INVALID_SEQUENCE_SETTLEMENT();
    error INVALID_REQUEST_SETTLEMENT();

    IManager internal immutable manager;
    address internal immutable participatingInterface;

    // For compatability with Tacen Alpha
    Id public lastSettlementIdProcessed = ID_ONE;
    Id public nextRequestId = Id.wrap(2);

    event ObligationsWritten(Id id, address requester, address token, uint256 cleared);

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IManager(_manager);
    }

    function processSettlement(
        bytes32 _stateRoot,
        StateUpdateLibrary.SignedStateUpdate calldata _settlementAcknowledgement,
        bytes32[] calldata _proof,
        StateUpdateLibrary.UTXO[] calldata _inputs
    )
        external
    {
        if (!manager.isValidator(msg.sender)) revert CALLER_NOT_VALIDATOR();
        confirmedStateRoot[epoch] = _stateRoot;
        _processSettlement(_settlementAcknowledgement, epoch, _proof, _inputs);
        epoch.increment();
    }

    /**
     * Called by anyone to complete a settlement.
     */
    function _processSettlement(
        StateUpdateLibrary.SignedStateUpdate calldata _signedUpdate,
        Id _stateRootId,
        bytes32[] calldata _proof,
        StateUpdateLibrary.UTXO[] calldata _inputs
    )
        internal
    {
        bytes32 stateRoot = confirmedStateRoot[_stateRootId];
        if (stateRoot == 0) revert EMPTY_STATE_ROOT();

        bool valid = MerkleProof.verifyCalldata(_proof, stateRoot, keccak256(abi.encode(_signedUpdate)));
        if (!valid) revert INVALID_PROOF_SETTLEMENT();

        if (_signedUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) {
            revert INVALID_STATE_UPDATE_SETTLEMENT();
        }

        StateUpdateLibrary.Settlement memory settlementAcknowledgement =
            abi.decode(_signedUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));

        if (_inputs.length != settlementAcknowledgement.inputs.length) {
            revert INPUTS_LENGTH_MISMATCH_SETTLEMENT();
        }

        StateUpdateLibrary.SettlementRequest memory settlementRequest = settlementAcknowledgement.settlementRequest;

        if (settlementRequest.settlementId != lastSettlementIdProcessed.increment()) {
            revert INVALID_SEQUENCE_SETTLEMENT();
        }

        if (
            !IPortal(manager.portal()).isValidSettlementRequest({
                chainSequenceId: Id.unwrap(settlementRequest.chainSequenceId),
                settlementHash: keccak256(abi.encode(settlementRequest))
            }) || settlementRequest.chainId != Id.wrap(block.chainid)
        ) revert INVALID_REQUEST_SETTLEMENT();

        unchecked {
            for (uint256 i = 0; i < _inputs.length; i++) {
                StateUpdateLibrary.UTXO calldata input = _inputs[i];
                bytes32 hashedInput = keccak256(abi.encode(input));

                if (hashedInput != settlementAcknowledgement.inputs[i]) {
                    revert INPUTS_HASH_MISMATCH_SETTLEMENT();
                }

                if (input.asset != settlementRequest.asset || input.trader != settlementRequest.trader) {
                    revert INPUT_PARAMS_MISMATCH_SETTLEMENT();
                }

                IPortal(manager.portal()).writeObligation({
                    utxo: hashedInput,
                    deposit: _inputs[i].depositUtxo,
                    recipient: _inputs[i].trader,
                    amount: _inputs[i].amount
                });
            }
            lastSettlementIdProcessed = lastSettlementIdProcessed.increment();
        }
        emit ObligationsWritten(
            settlementRequest.settlementId,
            settlementRequest.trader,
            settlementRequest.asset,
            IPortal(manager.portal()).getAvailableBalance(settlementRequest.trader, settlementRequest.asset)
            );
    }

    function requestSettlement(address _token, address _trader) external returns (uint256) {
        require(msg.sender == manager.portal(), "NOT_WALLET_SINGLETON");
        nextRequestId = nextRequestId.increment();
        unchecked {
            return Id.unwrap(nextRequestId) - 1;
        }
    }
}
