// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../StateUpdateLibrary.sol";
import "../util/Signature.sol";

/**
 * Meant to be deployed on a very-high throughput chain like a Polygon Supernet.
 * Used by the Participating Interface to publish data.
 */
contract StateUpdateStore is Signature {
    using IdLib for Id;

    Id public lastSequenceId = ID_ZERO;
    mapping(Id => Id) public lastChainSequenceId;
    address immutable participatingInterface;

    constructor(address _participatingInterface) Signature(_participatingInterface) {
        participatingInterface = _participatingInterface;
    }

    /**
     * Called by the participating interface to record state updates in calldata.
     *
     * This function provides highest throughput of data per transaction by limiting gas usage per state update.
     * However, it performs no validation on the data. Everything must be validated by SDPs and reported
     * within the fraud period.
     */
    function recordStateUpdates(StateUpdateLibrary.StateUpdate[] calldata stateUpdates) external view {
        require(msg.sender == participatingInterface, "recordStateUpdates: Sender not participating interface");
    }

    /**
     * Validates that the recovered address from the signature of the StateUpdate
     * matches the address of the participatingInterface.
     */
    function validateSignatures(StateUpdateLibrary.SignedStateUpdate[] calldata stateUpdates) internal view returns (bool) {
        for (uint256 i = 0; i < stateUpdates.length; i++) {
            StateUpdateLibrary.SignedStateUpdate memory signedStateUpdate = stateUpdates[i];
            StateUpdateLibrary.StateUpdate memory stateUpdate = signedStateUpdate.stateUpdate;

            bytes32 messageHash = typeHashStateUpdate(stateUpdate);
            address recoveredAddress = ecrecover(messageHash, signedStateUpdate.v, signedStateUpdate.r, signedStateUpdate.s);

            if (recoveredAddress != participatingInterface) {
                return false;
            }
        }
        return true;
    }

    /**
     * Validates that each `stateUpdate` is sorted by its `sequenceId`
     */
    function validateSequence(StateUpdateLibrary.SignedStateUpdate[] calldata stateUpdates) internal pure returns(bool) {
        for (uint256 i = 0; i < stateUpdates.length - 1; i++) {
            Id currentSequenceId = stateUpdates[i].stateUpdate.sequenceId;
            Id nextSequenceId = stateUpdates[i + 1].stateUpdate.sequenceId;
            if (!nextSequenceId.isSubsequent(currentSequenceId)) {
                return false;
            }
        }
        return true;
    }


    function reportStateUpdates(StateUpdateLibrary.SignedStateUpdate[] calldata stateUpdates, bytes32 root) external {
        // First StateUpdate must be next ID after last recorded sequence ID
        require(stateUpdates[0].stateUpdate.sequenceId.isSubsequent(lastSequenceId), "reportStateUpdates: First reported state update has incorrect sequence ID");

        // Iterate through reported state updates
        for(uint256 i = 0; i < stateUpdates.length; i++) {
            StateUpdateLibrary.SignedStateUpdate memory signedStateUpdate = stateUpdates[i];
            StateUpdateLibrary.StateUpdate memory stateUpdate = signedStateUpdate.stateUpdate;

            // Validate signature
            bytes32 messageHash = typeHashStateUpdate(stateUpdate);
            address recoveredAddress = ecrecover(messageHash, signedStateUpdate.v, signedStateUpdate.r, signedStateUpdate.s);
            require(recoveredAddress == participatingInterface, "Recovered address does not match participating interface address");

            // Validate that sequence IDs are ordered
            if(i < stateUpdates.length - 1) {
                require(stateUpdates[i+1].stateUpdate.sequenceId > stateUpdate.sequenceId, "reportStateUpdates: State updates are not ordered by sequence ID");
            }
            

            // Switch based on typeIdentifier
            if(stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_DepositAcknowledgement) {
                StateUpdateLibrary.DepositAcknowledgement memory depositAcknowledgement = abi.decode(stateUpdate.structData, (StateUpdateLibrary.DepositAcknowledgement));
                validateDepositAcknowledgement(depositAcknowledgement);
                incrementLastChainSequenceId(depositAcknowledgement.deposit.chainId);
            } else if (stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_Settlement) {
                StateUpdateLibrary.Settlement memory settlementAcknowledgement = abi.decode(stateUpdate.structData, (StateUpdateLibrary.Settlement));
                validateSettlementAcknowledgement(settlementAcknowledgement);
                incrementLastChainSequenceId(settlementAcknowledgement.settlementRequest.chainId);
            } else if (stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_Trade) {
                StateUpdateLibrary.Trade memory trade = abi.decode(stateUpdate.structData, (StateUpdateLibrary.Trade));
                validateTrade(trade);
            }
        }

        // Update last processed sequence ID
        lastSequenceId = stateUpdates[stateUpdates.length - 1].stateUpdate.sequenceId;
    }

    function validateDepositAcknowledgement(StateUpdateLibrary.DepositAcknowledgement memory depositAcknowledgement) internal view {
        require(depositAcknowledgement.deposit.chainSequenceId.isSubsequent(lastChainSequenceId[depositAcknowledgement.deposit.chainId]), "validateDepositAcknowledgement: DepositAcknowledgement is not ordered by chain sequence ID");
    }

    function validateSettlementAcknowledgement(StateUpdateLibrary.Settlement memory settlement) internal view {
        require(settlement.settlementRequest.chainSequenceId.isSubsequent(lastChainSequenceId[settlement.settlementRequest.chainId]), "validateSettlementAcknowledgement: SettlementAcknowledgement is not ordered by chain sequence ID");
    }

    function validateTrade(StateUpdateLibrary.Trade memory trade) internal pure {
        require(trade.params.orderA.price == trade.params.orderB.price, "validateTrade: Price in orders doesn't match");
    }

    function incrementLastChainSequenceId(Id chainId) internal {
        lastChainSequenceId[chainId] = lastChainSequenceId[chainId].increment();
    }
}
