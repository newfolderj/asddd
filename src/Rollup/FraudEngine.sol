// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IRollup.sol";
import "../Manager/IManager.sol";
import "../util/Signature.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";

contract FraudEngine is Signature {
    using IdLib for Id;

    error INVALID_MERKLE_PROOF();

    IManager immutable manager;
    address immutable participatingInterface;

    constructor(address _participatingInterface, address _manager) Signature(_participatingInterface) {
        manager = IManager(_manager);
        participatingInterface = _participatingInterface;
    }

    modifier marksFraudulent(Id _epoch) {
        _;
        IRollup(manager.rollup()).markFraudulent(Id.unwrap(_epoch));
    }

    function proveSignatureFraud(
        Id _epoch,
        StateUpdateLibrary.SignedStateUpdate calldata _invalidUpdate,
        bytes32[] calldata _proof
    )
        external
        marksFraudulent(_epoch)
    {
        proveStateUpdateInRoot({ _epoch: _epoch, _stateUpdate: _invalidUpdate, _proof: _proof });

        // prove signature is invalid
        bytes32 messageHash = typeHashStateUpdate(_invalidUpdate.stateUpdate);
        address recoveredAddress = ecrecover(messageHash, _invalidUpdate.v, _invalidUpdate.r, _invalidUpdate.s);
        if (recoveredAddress == participatingInterface) revert();
    }

    function proveInvalidOutput(
        Id _epoch,
        StateUpdateLibrary.SignedStateUpdate calldata _invalidUpdate,
        StateUpdateLibrary.UTXO[] calldata _inputs,
        uint256 _outputIndex,
        StateUpdateLibrary.UTXO calldata _output,
        bool _side,
        bytes32[] calldata _proof
    )
        external
        marksFraudulent(_epoch)
    {
        proveStateUpdateInRoot({ _epoch: _epoch, _stateUpdate: _invalidUpdate, _proof: _proof });

        // Get trade
        StateUpdateLibrary.StateUpdate memory stateUpdate = _invalidUpdate.stateUpdate;
        if (stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
        StateUpdateLibrary.Trade memory trade = abi.decode(stateUpdate.structData, (StateUpdateLibrary.Trade));

        // Prove specified output is part of the trade
        proveUtxoInTrade({
            _trade: trade,
            _utxo: keccak256(abi.encode(_output)),
            _index: _outputIndex,
            _side: _side,
            _inputsOrOutputs: false
        });

        // Iterate through inputs and show that none of them are parents of the output
        bytes32[] memory hashedInputs = _side ? trade.inputsA : trade.inputsB;
        for (uint256 i = 0; i < hashedInputs.length; i++) {
            StateUpdateLibrary.UTXO calldata input = _inputs[i];
            // input hashes should match
            if (hashedInputs[i] != keccak256(abi.encode(input))) revert();

            // parent does not match
            if (_output.parentUtxo == hashedInputs[i]) revert();
        }

        // If above loop ends with reverting, there are no input UTXOs which
        // match the parent of the output.
    }

    // Proves an input or output asset doesn't match the trade params
    function proveAssetMismatchTrade(
        Id _epoch,
        StateUpdateLibrary.SignedStateUpdate calldata _invalidUpdate,
        StateUpdateLibrary.UTXO calldata _mismatched,
        uint256 _index,
        bool _inputsOrOutputs,
        bool _side,
        bytes32[] calldata _proof
    )
        external
        marksFraudulent(_epoch)
    {
        proveStateUpdateInRoot({ _epoch: _epoch, _stateUpdate: _invalidUpdate, _proof: _proof });

        // Get trade
        StateUpdateLibrary.StateUpdate calldata stateUpdate = _invalidUpdate.stateUpdate;
        if (stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
        StateUpdateLibrary.Trade memory trade = abi.decode(stateUpdate.structData, (StateUpdateLibrary.Trade));

        // Prove specified UTXO is part of the trade
        proveUtxoInTrade({
            _trade: trade,
            _utxo: keccak256(abi.encode(_mismatched)),
            _index: _index,
            _side: _side,
            _inputsOrOutputs: _inputsOrOutputs
        });

        // Prove asset of UTXO does not match asset in trade
        address expectedAsset = _side ? trade.params.product.assetA : trade.params.product.assetB;
        uint256 expectedChainId = _side ? trade.params.product.chainIdA : trade.params.product.chainIdB;
        if (_mismatched.asset == expectedAsset && _mismatched.chainId == Id.wrap(expectedChainId)) revert();
    }

    // Prove that an input used in a settlement is for an asset that doesn't match the settlement
    function proveAssetMismatchSettlement(
        Id _epoch,
        StateUpdateLibrary.SignedStateUpdate calldata _invalidUpdate,
        StateUpdateLibrary.UTXO calldata _mismatched,
        uint256 _index,
        bytes32[] calldata _proof
    )
        external
        marksFraudulent(_epoch)
    {
        // prove update exists in state root
        // decode into Settlement
        // hash of _mismatched exists as input in settlement
        // asset of _mismatched != asset of Settlement
    }

    struct DoubleSpendProofInput {
        Id epoch;
        StateUpdateLibrary.SignedStateUpdate update;
        bytes32[] proof;
        bytes32 input;
        uint256 index;
        bool tradeOrSettlement;
        bool side;
    }

    function proveDoubleSpendInput(DoubleSpendProofInput[2] calldata _proofs)
        external
        marksFraudulent(_proofs[0].epoch)
    {
        if (keccak256(abi.encode(_proofs[0].update)) == keccak256(abi.encode(_proofs[1].update))) revert();
        for (uint256 i = 0; i < 2; i++) {
            proveStateUpdateInRoot({
                _epoch: _proofs[i].epoch,
                _stateUpdate: _proofs[i].update,
                _proof: _proofs[i].proof
            });
            StateUpdateLibrary.StateUpdate calldata stateUpdate = _proofs[i].update.stateUpdate;
            // Decode and check first state update
            if (_proofs[i].tradeOrSettlement) {
                if (stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
                StateUpdateLibrary.Trade memory trade = abi.decode(stateUpdate.structData, (StateUpdateLibrary.Trade));
                proveUtxoInTrade({
                    _trade: trade,
                    _utxo: _proofs[i].input,
                    _index: _proofs[i].index,
                    _side: _proofs[i].side,
                    _inputsOrOutputs: true
                });
            } else {
                if (stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) revert();
                StateUpdateLibrary.Settlement memory settlement =
                    abi.decode(stateUpdate.structData, (StateUpdateLibrary.Settlement));
                if (settlement.inputs[_proofs[i].index] != _proofs[i].input) revert();
            }
        }
    }

    struct DoubleSpendProofOutput {
        Id epoch;
        StateUpdateLibrary.SignedStateUpdate update;
        bytes32[] proof;
        bytes32 output;
        uint256 index;
        bool tradeOrDeposit;
        bool side;
    }

    function proveDoubleSpendOutput(DoubleSpendProofOutput[2] calldata _proofs)
        external
        marksFraudulent(_proofs[0].epoch)
    {
        if (keccak256(abi.encode(_proofs[0].update)) == keccak256(abi.encode(_proofs[1].update))) revert();
        for (uint256 i = 0; i < 2;) {
            proveStateUpdateInRoot({
                _epoch: _proofs[i].epoch,
                _stateUpdate: _proofs[i].update,
                _proof: _proofs[i].proof
            });
            StateUpdateLibrary.StateUpdate calldata stateUpdate = _proofs[i].update.stateUpdate;
            // Decode and check first state update
            if (_proofs[i].tradeOrDeposit) {
                if (stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
                StateUpdateLibrary.Trade memory trade = abi.decode(stateUpdate.structData, (StateUpdateLibrary.Trade));
                proveUtxoInTrade({
                    _trade: trade,
                    _utxo: _proofs[i].output,
                    _index: _proofs[i].index,
                    _side: _proofs[i].side,
                    _inputsOrOutputs: false
                });
            } else {
                if (stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_DepositAcknowledgement) revert();
                StateUpdateLibrary.DepositAcknowledgement memory deposit =
                    abi.decode(stateUpdate.structData, (StateUpdateLibrary.DepositAcknowledgement));
                if (deposit.output != _proofs[i].output) revert();
            }
            unchecked {
                i++;
            }
        }
    }

    // A state update specifies an input. The state update which is supposed to
    // have generated doesn't actually have the hash as an output.
    //
    // Another thing to check is that output type identifier is Deposit or Trade
    //
    function proveOutputNonexistent(
        // State update trying to use an input that doesn't exist
        Id _inputEpoch,
        StateUpdateLibrary.SignedStateUpdate calldata _inputUpdate,
        bytes32[] calldata _inputUpdateProof,
        uint256 _inputIndex,
        bool _tradeOrSettlement,
        bool side,
        // State update referenced in output
        Id _epochOutput,
        StateUpdateLibrary.SignedStateUpdate calldata _outputUpdate,
        bytes32[] calldata _outputUpdateProof,
        bool tradeOrDeposit
    )
        external
    {
        // Iterate through all outputs
        // validate that none of the outputs match the input hash
    }

    // A deposit state update generates an invalid output
    function proveDepositOutputInvalid(
        Id _epochOutput,
        StateUpdateLibrary.SignedStateUpdate calldata _outputUpdate,
        bytes32[] calldata _outputUpdateProof,
        StateUpdateLibrary.UTXO calldata _invalidOutput
    )
        external
    {
        // show deposit is in state root of epoch
        // validate type identifier matches deposit
        // show _invalidOutput hashes to output of deposit
        // show output doesn't match actual deposit
        // asset/chain ID doesn't match on-chain OR
        // amount doesn't match on-chain OR
        // trader doesn't match on-chain
    }

    function proveSettlementInputInvalid(
        Id _epochOutput,
        StateUpdateLibrary.SignedStateUpdate calldata _outputUpdate,
        bytes32[] calldata _outputUpdateProof,
        uint256 _index,
        StateUpdateLibrary.UTXO calldata _invalidInput
    )
        external
    {
        // show settlement is in state root of epoch
        // validate type identifier matches settlement
        // show _invalidInput is in list of hashed inputs at _index
        // show that either:
        //  - asset of input doesn't match asset of settlement
        //  - trader address of input doesn't match trader address of settlement
    }

    // Settlement or deposit in state update doesn't match what's on-chain
    function proveSettlementInvalid() external { }
    function proveDepositInvalid() external { }

    // Given an output's state update ID:
    //  - the state update that includes it has a different ID
    //  - the state update referenced does not have the output
    function proveOutputInvalidSequenceId() external { }

    // Prove a state update is in the wrong position relative to its ID
    function proveInvalidStateUpdateSequence() external {
        // prove state update exists in epoch
        // validate its type identifier
        // prove:
        //  - first state update ID >= second state update ID
        //  - first index < second index
    }

    // Prove a state update is in the wrong position relative to the chain sequence ID
    // of its on-chain event
    function proveInvalidChainSequence() external {
        // prove state update exists in epoch
        // validate its type identifier
        // prove it has event with chainSequenceId
        // prove:
        //  - first chain ID == second chain ID
        //  - first chain seq ID >= second chain seq ID
        //  - first state update ID > second state update ID
    }

    // Prove that a state update is trying to use an input
    // which is generated in a state update that comes afterwards
    function proveInputOutOfSequence() external {
        // prove state update exists in epoch
        // validate its type identifier as trade or settlement
        // prove it has UTXO as input
        // prove other state update exists in epoch
        // validate its type identifier as trade or deposit
        // prove it has UTXO as output
        // prove firstUpdate.ID <= secondUpdate.ID
    }

    // Avoids stack too deep error
    struct FeeInputProofParams {
        Id inputEpoch;
        // Trade or Settlement attempting to use the input
        StateUpdateLibrary.SignedStateUpdate inputUpdate;
        uint256 inputIndex;
        bool tradeOrSettlement;
        bool inputSide;
        // State update where the corresponding output was generated as a fee
        Id outputEpoch;
        StateUpdateLibrary.SignedStateUpdate outputUpdate;
        uint256 outputIndex;
    }

    // Show that a fee output was used as an input
    function proveFeeInput(
        FeeInputProofParams calldata _params,
        bytes32[] calldata _inputUpdateProof,
        bytes32[] calldata _outputUpdateProof
    )
        external marksFraudulent(_params.inputEpoch)
    {
        // prove inclusion of trade that uses fee as input in root
        proveStateUpdateInRoot({
            _epoch: _params.inputEpoch,
            _stateUpdate: _params.inputUpdate,
            _proof: _inputUpdateProof
        });
        bytes32 utxo;
        if (_params.tradeOrSettlement) {
            if (_params.inputUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
            StateUpdateLibrary.Trade memory invalidTrade =
                abi.decode(_params.inputUpdate.stateUpdate.structData, (StateUpdateLibrary.Trade));
            // Get input UTXO from trade
            utxo = getUtxoFromTrade({
                _trade: invalidTrade,
                _index: _params.inputIndex,
                _side: _params.inputSide,
                _inputsOrOutputs: true
            });
        } else {
            if (_params.inputUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) revert();
            StateUpdateLibrary.Settlement memory settlement =
                abi.decode(_params.inputUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));
            // Get input UTXO from settlement
            utxo = settlement.inputs[_params.inputIndex];
        }

        // prove inclusion of trade that has above input as a fee output
        proveStateUpdateInRoot({
            _epoch: _params.outputEpoch,
            _stateUpdate: _params.outputUpdate,
            _proof: _outputUpdateProof
        });
        // Get trade
        if (_params.outputUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
        StateUpdateLibrary.Trade memory trade =
            abi.decode(_params.outputUpdate.stateUpdate.structData, (StateUpdateLibrary.Trade));
        // Assert that above input is a fee output of the trade
        if (trade.feeOutputs[_params.outputIndex] != utxo) revert();
    }

    // Proves that a fee output was improperly generated
    function proveInvalidFee(
        Id _tradeEpoch,
        StateUpdateLibrary.SignedStateUpdate calldata _trade,
        bytes32[] calldata _tradeProof,
        bool _side,
        uint256 _outputIndex,
        StateUpdateLibrary.UTXO calldata _output,
        uint256 _feeOutputIndex,
        StateUpdateLibrary.UTXO calldata _feeOutput,
        uint256 _inputIndex,
        StateUpdateLibrary.UTXO calldata _input
    )
        external
    {
        // prove inclusion of trade in root
        proveStateUpdateInRoot({ _epoch: _tradeEpoch, _stateUpdate: _trade, _proof: _tradeProof });
        // validate that update is a trade
        if (_trade.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
        StateUpdateLibrary.Trade memory trade = abi.decode(_trade.stateUpdate.structData, (StateUpdateLibrary.Trade));
        // prove input, output, and fee output are in trade

        // TODO: determine maker and taker
        // validate that input and output/feeOutput match
        // get fee rate using feeSequenceId
        // mulitply input amount by fee rate
        // assert output = input - calculatedFee
        // assert feeOutput != calculatedFee
    }

    // Prove that a Trade should be using a different Fee Sequence Id
    function proveTradeFeeId(
        Id _tradeEpoch,
        StateUpdateLibrary.SignedStateUpdate calldata _trade,
        bytes32[] calldata _tradeProof,
        // Optional if first condition is triggered
        Id _feeEpoch,
        StateUpdateLibrary.SignedStateUpdate calldata _fee,
        bytes32[] calldata _feeProof,
        // Optional if 1st or 2nd failure condition is triggered
        Id _canonFeeEpoch,
        StateUpdateLibrary.SignedStateUpdate calldata _canonFee,
        bytes32[] calldata _canonFeeProof
    )
        external
        marksFraudulent(_tradeEpoch)
    {
        // prove inclusion of trade in root
        proveStateUpdateInRoot({ _epoch: _tradeEpoch, _stateUpdate: _trade, _proof: _tradeProof });
        // Get trade
        if (_trade.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
        StateUpdateLibrary.Trade memory trade = abi.decode(_trade.stateUpdate.structData, (StateUpdateLibrary.Trade));
        // Failure condition 1: Fee Update referenced by trade is after trade in sequence
        if (trade.feeUpdateId >= _trade.stateUpdate.sequenceId) return;

        // Prove trade references fee update
        if (trade.feeUpdateId != _fee.stateUpdate.sequenceId) revert();
        // prove inclusion of fee update in root
        proveStateUpdateInRoot({ _epoch: _feeEpoch, _stateUpdate: _fee, _proof: _feeProof });
        // Failure Condition 2: State update referenced by trade is not a fee update
        if (_fee.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_FeeUpdate) return;

        // prove inclusion of canon fee in root
        proveStateUpdateInRoot({ _epoch: _canonFeeEpoch, _stateUpdate: _canonFee, _proof: _canonFeeProof });
        if (_canonFee.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_FeeUpdate) revert();
        // Failure Condition 3: Canon fee is more recent than referenced fee
        if (
            _trade.stateUpdate.sequenceId > _canonFee.stateUpdate.sequenceId
                && _canonFee.stateUpdate.sequenceId > _fee.stateUpdate.sequenceId
        ) return;

        // Reached the end without triggering any failure conditions
        revert();
    }

    // Prove that state update referenced by a fee is not a fee update
    function proveFeeInvalidStateUpdateId() external { }

    function proveStateUpdateInRoot(
        Id _epoch,
        StateUpdateLibrary.SignedStateUpdate calldata _stateUpdate,
        bytes32[] calldata _proof
    )
        internal
        view
    {
        bytes32 stateRoot = IRollup(manager.rollup()).getProposedStateRoot(Id.unwrap(_epoch));
        // prove element is in stateRoot
        bool valid = MerkleProof.verifyCalldata(_proof, stateRoot, keccak256(abi.encode(_stateUpdate)));
        if (!valid) revert INVALID_MERKLE_PROOF();
    }

    function getUtxoFromTrade(
        StateUpdateLibrary.Trade memory _trade,
        uint256 _index,
        bool _side,
        bool _inputsOrOutputs
    )
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory hashes = _side
            ? (_inputsOrOutputs ? _trade.inputsA : _trade.outputsA)
            : (_inputsOrOutputs ? _trade.inputsB : _trade.outputsB);
        return hashes[_index];
    }

    function proveUtxoInTrade(
        StateUpdateLibrary.Trade memory _trade,
        bytes32 _utxo,
        uint256 _index,
        bool _side,
        bool _inputsOrOutputs
    )
        internal
        pure
    {
        // Prove specified UTXO is part of the trade
        bytes32[] memory hashes = _side
            ? (_inputsOrOutputs ? _trade.inputsA : _trade.outputsA)
            : (_inputsOrOutputs ? _trade.inputsB : _trade.outputsB);
        if (hashes[_index] != _utxo) revert();
    }
}
