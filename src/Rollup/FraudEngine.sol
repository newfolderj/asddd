// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IRollup.sol";
import "../Portal/Deposits.sol";
import "../Manager/IBaseManager.sol";
import "../util/Signature.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FraudEngine is Signature {
    using IdLib for Id;

    error INVALID_MERKLE_PROOF();

    IBaseManager immutable manager;
    address immutable participatingInterface;

    constructor(address _participatingInterface, address _manager) Signature(_participatingInterface) {
        manager = IBaseManager(_manager);
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
        assertStateUpdateInRoot({ _epoch: _epoch, _stateUpdate: _invalidUpdate, _proof: _proof });

        // prove signature is invalid
        bytes32 messageHash = typeHashStateUpdate(_invalidUpdate.stateUpdate);
        address recoveredAddress = ecrecover(messageHash, _invalidUpdate.v, _invalidUpdate.r, _invalidUpdate.s);
        if (recoveredAddress == participatingInterface) revert();
    }

    struct StateUpdateProof {
        Id epoch;
        StateUpdateLibrary.SignedStateUpdate update;
        bytes32[] proof;
    }

    function proveDepositAcknowledgementInvalid(
        Id _invalidUpdateEpoch,
        StateUpdateLibrary.SignedStateUpdate calldata _invalidUpdate,
        bytes32[] calldata _invalidUpdateProof,
        StateUpdateProof calldata _prevUpdate,
        StateUpdateProof calldata _canonUpdate
    )
        external
    {
        // Does fraudulent Deposit Ack exist?
        // assert deposit state update in state root
        assertStateUpdateInRoot({
            _epoch: _invalidUpdateEpoch,
            _stateUpdate: _invalidUpdate,
            _proof: _invalidUpdateProof
        });
        // assert that state update has deposit ack
        if (_invalidUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_DepositAcknowledgement) revert();
        // get deposit ack
        StateUpdateLibrary.DepositAcknowledgement memory depositAck =
            abi.decode(_invalidUpdate.stateUpdate.structData, (StateUpdateLibrary.DepositAcknowledgement));

        // Condition 1
        // Does fraudulent deposit ack match the on-chain deposit?
        // prove record of deposit doesn't exist on-chain
        // TODO: need to get deposits from ProcessingChainLz
        bytes32 depositHash = keccak256(abi.encode(depositAck.deposit));
        (address trader, address asset, address _participatingInterface, uint64 amount, Id chainSequenceId, Id chainId)
        = Deposits(address(manager)).deposits(depositHash);
        // if deposit stored in Portal under hash doesn't match the deposit in the depositAck, then the state update is
        // fraudulent
        if (
            depositHash
                != keccak256(
                    abi.encode(
                        StateUpdateLibrary.Deposit(trader, asset, participatingInterface, amount, chainSequenceId, chainId)
                    )
                )
        ) return;

        // prove trader of on-chain record != trader of old balance
        if (trader != depositAck.balanceBefore.trader) return;
        // prove asset of on-chain record != asset of old balance
        if (asset != depositAck.balanceBefore.asset || chainId != depositAck.balanceBefore.chainId) return;

        // prove trader of on-chain record != trader of new balance
        if (trader != depositAck.balanceAfter.trader) return;
        // prove asset of on-chain record doesn't match asset of new balance
        if (asset != depositAck.balanceAfter.asset || chainId != depositAck.balanceAfter.chainId) return;

        // prove on-chain amount + old balance amount != new balance amount
        if (depositAck.balanceAfter.amount != depositAck.balanceBefore.amount + amount) return;

        // Condition 2
        // Does fraudulent deposit ack reference an invalid previous balance state update?
        // prove balanceBeforeId of invalidUpdate >= stateUpdateId of invalidUpdate
        if (depositAck.balanceBeforeId >= _invalidUpdate.stateUpdate.sequenceId) return;
        // assert balanceBeforeId == id of prevUpdate
        if (_prevUpdate.update.stateUpdate.sequenceId != depositAck.balanceBeforeId) revert();
        // assert prevUpdate in prevUpdateEpoch root
        assertStateUpdateInRoot({
            _epoch: _prevUpdate.epoch,
            _stateUpdate: _prevUpdate.update,
            _proof: _prevUpdate.proof
        });
        if (_prevUpdate.update.stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_DepositAcknowledgement) {
            // get deposit ack
            StateUpdateLibrary.DepositAcknowledgement memory prevDepositAck =
                abi.decode(_prevUpdate.update.stateUpdate.structData, (StateUpdateLibrary.DepositAcknowledgement));
            // prove that chainId of prevDepositAck != chainId of this deposit
            if (prevDepositAck.deposit.chainId != chainId) return;

            // prove that new balance of prevDepositAck doesn't match old balance of this deposit
            if (!balancesEqual(prevDepositAck.balanceAfter, depositAck.balanceBefore)) return;

            // prove that chainSequenceId of prevDepositAck >= chainSequenceId of this deposit
            if (prevDepositAck.deposit.chainSequenceId >= chainSequenceId) return;
        } else if (_prevUpdate.update.stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_Trade) {
            // get trade
            StateUpdateLibrary.Trade memory prevTrade =
                abi.decode(_prevUpdate.update.stateUpdate.structData, (StateUpdateLibrary.Trade));
            // loop through output balances of trade
            if (balancesMatch(depositAck.balanceBefore, prevTrade.makerBaseBalanceBefore)) {
                if (depositAck.balanceBefore.amount != prevTrade.makerBaseBalanceAfter) return;
            } else if (balancesMatch(depositAck.balanceBefore, prevTrade.takerBaseBalanceBefore)) {
                if (depositAck.balanceBefore.amount != prevTrade.takerBaseBalanceAfter) return;
            } else if (balancesMatch(depositAck.balanceBefore, prevTrade.makerCounterBalanceBefore)) {
                if (depositAck.balanceBefore.amount != prevTrade.makerCounterBalanceAfter) return;
            } else if (balancesMatch(depositAck.balanceBefore, prevTrade.takerCounterBalanceBefore)) {
                if (depositAck.balanceBefore.amount != prevTrade.takerCounterBalanceAfter) return;
            }
        } else if (_prevUpdate.update.stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_Settlement) {
            // get settlement
            StateUpdateLibrary.Settlement memory prevSettlement =
                abi.decode(_prevUpdate.update.stateUpdate.structData, (StateUpdateLibrary.Settlement));
            // prove that output balance of settlement is not same as old balance of deposit ack
            if (!balancesEqual(depositAck.balanceBefore, prevSettlement.balanceAfter)) return;
        } else {
            revert();
        }

        // Condition 3
        // Is there a more recent state update that should be used as the source of the old balance?
        // assert canon state update in canon root
        assertStateUpdateInRoot({
            _epoch: _canonUpdate.epoch,
            _stateUpdate: _canonUpdate.update,
            _proof: _canonUpdate.proof
        });

        // assert that stateUpdateId of canon state update > balanceBeforeId
        if (!(_canonUpdate.update.stateUpdate.sequenceId > depositAck.balanceBeforeId)) revert();
        // assert that id of invalid update > id of canon update
        if (!(_invalidUpdate.stateUpdate.sequenceId > _canonUpdate.update.stateUpdate.sequenceId)) revert();
        if (_canonUpdate.update.stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_DepositAcknowledgement) {
            // get deposit ack
            StateUpdateLibrary.DepositAcknowledgement memory canonDepositAck =
                abi.decode(_canonUpdate.update.stateUpdate.structData, (StateUpdateLibrary.DepositAcknowledgement));
            // assert that chainId of invalid deposit ack == chainId of canon deposit ack
            if (canonDepositAck.deposit.chainId != depositAck.deposit.chainId) revert();
            // assert that chainSequenceId of invalid deposit ack > chainSequenceId of canon deposit ack
            if (!(depositAck.deposit.chainSequenceId > canonDepositAck.deposit.chainSequenceId)) revert();
            // prove that new balance of canon deposit ack matches old balance of this deposit
            if (balancesMatch(canonDepositAck.balanceAfter, depositAck.balanceBefore)) return;
        } else if (_canonUpdate.update.stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_Trade) {
            // get trade
            StateUpdateLibrary.Trade memory canonTrade =
                abi.decode(_canonUpdate.update.stateUpdate.structData, (StateUpdateLibrary.Trade));
            // prove that an output balance of canon trade matches old balance of deposit ack
            if (
                balancesMatch(depositAck.balanceBefore, canonTrade.makerBaseBalanceBefore)
                    || balancesMatch(depositAck.balanceBefore, canonTrade.takerBaseBalanceBefore)
                    || balancesMatch(depositAck.balanceBefore, canonTrade.makerCounterBalanceBefore)
                    || balancesMatch(depositAck.balanceBefore, canonTrade.takerCounterBalanceBefore)
            ) {
                return;
            }
        } else if (_canonUpdate.update.stateUpdate.typeIdentifier == StateUpdateLibrary.TYPE_ID_Settlement) {
            // get settlement
            StateUpdateLibrary.Settlement memory canonSettlement =
                abi.decode(_canonUpdate.update.stateUpdate.structData, (StateUpdateLibrary.Settlement));

            // assert that chainSequenceId of invalid deposit ack > chainSequenceId of canon settlement
            if (!(depositAck.deposit.chainSequenceId > canonSettlement.settlementRequest.chainSequenceId)) revert();
            // prove that output balance of settlement matches old balance of deposit ack
            if (balancesMatch(depositAck.balanceBefore, canonSettlement.balanceAfter)) return;
        } else {
            revert();
        }

        // reaching end without returning means fraud proof was invalid
        revert();
    }

    struct StateTreeProofs {
        bytes32[] proofs;
        uint8 bits;
    }

    function proveDepositAcknowledgementIncorrectRootUpdate(
        Id _depositEpoch,
        StateUpdateLibrary.SignedStateUpdate calldata _invalidUpdate,
        StateTreeProofs calldata _stateTreeProofs
    )
        external
    {
        // assert deposit state update in state root

        // assert that state update has deposit ack
        // get deposit ack

        // update prev root by writing hash of deposit to same index as chain sequence ID
        // StateTree.write(_stateTreeProofs.proofs, _stateTreeProofs.bits, chainSequenceId,
        // keccak256(abi.encode(depositAck)), emptyLeaf, prevRoot)

        // prove that new root in state update == calculated root
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
        assertStateUpdateInRoot({ _epoch: _tradeEpoch, _stateUpdate: _trade, _proof: _tradeProof });
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
        assertStateUpdateInRoot({ _epoch: _tradeEpoch, _stateUpdate: _trade, _proof: _tradeProof });
        // Get trade
        if (_trade.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade) revert();
        StateUpdateLibrary.Trade memory trade = abi.decode(_trade.stateUpdate.structData, (StateUpdateLibrary.Trade));
        // Failure condition 1: Fee Update referenced by trade is after trade in sequence
        if (trade.feeUpdateId >= _trade.stateUpdate.sequenceId) return;

        // Prove trade references fee update
        if (trade.feeUpdateId != _fee.stateUpdate.sequenceId) revert();
        // prove inclusion of fee update in root
        assertStateUpdateInRoot({ _epoch: _feeEpoch, _stateUpdate: _fee, _proof: _feeProof });
        // Failure Condition 2: State update referenced by trade is not a fee update
        if (_fee.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_FeeUpdate) return;

        // prove inclusion of canon fee in root
        assertStateUpdateInRoot({ _epoch: _canonFeeEpoch, _stateUpdate: _canonFee, _proof: _canonFeeProof });
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

    function getOutputBalances(StateUpdateLibrary.Trade memory _trade) internal returns (uint256[4] memory) {
        return [
            _trade.makerBaseBalanceAfter,
            _trade.makerCounterBalanceAfter,
            _trade.takerBaseBalanceAfter,
            _trade.takerCounterBalanceAfter
        ];
    }

    function balancesEqual(
        StateUpdateLibrary.Balance memory _a,
        StateUpdateLibrary.Balance memory _b
    )
        internal
        pure
        returns (bool)
    {
        return (_a.asset == _b.asset && _a.chainId == _b.chainId && _a.trader == _b.trader && _a.amount == _b.amount);
    }

    // Same as above, but does not check amount
    function balancesMatch(
        StateUpdateLibrary.Balance memory _a,
        StateUpdateLibrary.Balance memory _b
    )
        internal
        pure
        returns (bool)
    {
        return (_a.asset == _b.asset && _a.chainId == _b.chainId && _a.trader == _b.trader);
    }

    function assertStateUpdateInRoot(
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
}
