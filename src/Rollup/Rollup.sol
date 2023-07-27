// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IRollup.sol";
import "../Oracle/IOracle.sol";
import "../CrossChain/LayerZero/IProcessingChainLz.sol";
import "../Portal/IPortal.sol";
import "../Manager/ProcessingChain/IProcessingChainManager.sol";
import "../Manager/ProcessingChain/IFeeManager.sol";
import "../Staking/IStaking.sol";
import "../StateUpdateLibrary.sol";
import "../util/Id.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Rollup
/// @author Arseniy Klempner
/// @notice Deployed on the processing chain. Allows validators to propose state roots containing state updates that
/// were signed and broadcast by the participating interface. Based on data that was included in state roots, the
/// validator can process traders' settlement requests and relay the information to the corresponding Portal. If the
/// state root has not yet been confirmed, then the settlment will require collateral to be locked from the Staking
/// contract. Stakers who contributed collateral will earn a portion of settlement fees as a reward. The participating
/// interface can also claim trading fees from confirmed state roots based on the included trades.
contract Rollup is IRollup {
    using IdLib for Id;
    using EnumerableSet for EnumerableSet.UintSet;

    /// Incremental identifier to track history of proposed state roots
    Id public epoch = ID_ONE;
    /// Incremental identifier to track the last state root that was confirmed
    Id public lastConfirmedEpoch = ID_ZERO;
    /// Maps Id of the epoch to the state root proposed for the epoch
    mapping(Id => bytes32) public proposedStateRoot;
    /// Maps state root to block number when state root was proposed
    mapping(bytes32 => uint256) public proposalBlock;
    /// Maps epoch to state root to a flag indicating if the state root was marked as fraudulent for that epoch.
    mapping(Id => mapping(bytes32 => bool)) public fraudulent;
    /// Maps epoch Id to the state root that was confirmed for that epoch
    mapping(Id => bytes32) public confirmedStateRoot;
    /// Maps epoch to state root to state update sequence ID to boolean flag indicating if the settlement with that
    /// sequnence ID has been processed
    mapping(Id => mapping(bytes32 => EnumerableSet.UintSet)) internal processedSettlements;
    /// Maps sequnce ID of state update to whether or not its fee(s) have been claimed by the participating interface
    mapping(Id => bool) internal tradeClaimed;
    /// Maps chain ID to asset address to amount that has been claimed as fees and is awaiting relay
    mapping(Id => mapping(address => uint256)) internal tradingFees;

    struct StateRootRecord {
        bytes32 stateRoot;
        Id epoch;
    }

    /// Tracks each time a state root is used to lock collateral for a settlement
    mapping(uint256 => StateRootRecord) internal lockIdStateRoot;

    event SettlementFeePaid(address indexed trader, uint256 indexed chainId, address indexed token, uint256 amount);

    error CALLER_NOT_VALIDATOR();
    error EMPTY_STATE_ROOT();
    error INVALID_PROOF_SETTLEMENT();
    error INVALID_STATE_UPDATE_SETTLEMENT();
    error INPUTS_LENGTH_MISMATCH_SETTLEMENT();
    error INPUTS_HASH_MISMATCH_SETTLEMENT();
    error INPUT_PARAMS_MISMATCH_SETTLEMENT();
    error INVALID_SEQUENCE_SETTLEMENT();
    error INVALID_REQUEST_SETTLEMENT();
    error EPOCH_NOT_CONFIRMED();
    error INVALID_PROOF_REJECTED_DEPOSIT();
    error INVALID_STATE_UPDATE_REJECTED_DEPOSIT();
    error CALLER_NOT_PORTAL(address sender, address expected);

    IProcessingChainManager internal immutable manager;
    address internal immutable participatingInterface;

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IProcessingChainManager(_manager);
    }

    /// Called by the validator to propose a state root
    function proposeStateRoot(bytes32 _stateRoot) external {
        if (!manager.isValidator(msg.sender)) revert CALLER_NOT_VALIDATOR();
        if (_stateRoot == "") revert("Proposed empty state root");
        IStaking staking = IStaking(manager.staking());
        uint256 lockId = staking.lock(staking.protocolToken(), manager.rootProposalLockAmount());

        proposedStateRoot[epoch] = _stateRoot;
        proposalBlock[_stateRoot] = block.number;
        lockIdStateRoot[lockId] = StateRootRecord(_stateRoot, epoch);
        epoch = epoch.increment();
    }

    /// If a state root has not yet been confirmed and no settlements have been processed, the validator can replace the
    /// state root in case of errors.
    function replaceStateRoot(bytes32 _stateRoot, Id _epoch) external {
        if (!manager.isValidator(msg.sender)) revert CALLER_NOT_VALIDATOR();
        if (lastConfirmedEpoch >= _epoch) revert("Cannot replace state root that's been confirmed");
        if(processedSettlements[_epoch][_stateRoot].length() > 0) revert("A settlement has already been processed for this state root");

        proposedStateRoot[_epoch] = _stateRoot;
        proposalBlock[_stateRoot] = block.number;
    }

    /// Called by the validator to confirm a state root
    function confirmStateRoot() external {
        if (!manager.isValidator(msg.sender)) revert CALLER_NOT_VALIDATOR();
        lastConfirmedEpoch = lastConfirmedEpoch.increment();

        bytes32 stateRoot = proposedStateRoot[lastConfirmedEpoch];
        if (stateRoot == "") revert("Trying to confirm an empty state root");

        uint256 blockNumber = proposalBlock[stateRoot];
        if (block.number < blockNumber + manager.fraudPeriod()) {
            revert("Proposed state root has not passed fraud period");
        }

        if (fraudulent[lastConfirmedEpoch][stateRoot]) revert("Trying to confirm a fraudulent state root");

        confirmedStateRoot[lastConfirmedEpoch] = stateRoot;
    }

    // Used to get around the "stack too deep" limitation of Solidity
    struct ProcessSettlementState {
        bytes32 stateRoot;
        StateUpdateLibrary.Settlement settlement;
        uint256 stablecoinValue;
    }

    struct SettlementParams {
        StateUpdateLibrary.SignedStateUpdate signedUpdate;
        Id stateRootId;
        bytes32[] proof;
    }

    function processSettlements(Id _chainId, SettlementParams[] calldata _params) external payable {
        if (!manager.isValidator(msg.sender)) revert("Only validator can process settlements");
        ProcessSettlementState memory state;
        IPortal.Obligation[] memory obligations = new IPortal.Obligation[](_params.length);
        for (uint256 i = 0; i < _params.length; i++) {
            bool requiresCollateral = false;
            state.stateRoot = confirmedStateRoot[_params[i].stateRootId];
            if (state.stateRoot == 0) {
                requiresCollateral = true;
                state.stateRoot = proposedStateRoot[_params[i].stateRootId];
                if (state.stateRoot == 0) revert EMPTY_STATE_ROOT();
            }
            {
                bool valid = MerkleProof.verifyCalldata(
                    _params[i].proof, state.stateRoot, keccak256(abi.encode(_params[i].signedUpdate))
                );
                if (!valid) revert INVALID_PROOF_SETTLEMENT();

                if (_params[i].signedUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) {
                    revert INVALID_STATE_UPDATE_SETTLEMENT();
                }

                // Check if settlement has already been processed
                if (
                    processedSettlements[_params[i].stateRootId][state.stateRoot].contains(
                        Id.unwrap(_params[i].signedUpdate.stateUpdate.sequenceId)
                    )
                ) revert("Settlement already processed");
            }

            state.settlement =
                abi.decode(_params[i].signedUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));
            {
                // Only process settlements for assets of the same chain ID.
                // This limits the final relay to a single chain.
                if (state.settlement.settlementRequest.chainId != _chainId) {
                    revert("Settlement request chainId doesn't match _chainId");
                }

                // Validate the balance in the settlement and the trader/asset of the settlement request
                if (
                    state.settlement.balanceBefore.asset != state.settlement.settlementRequest.asset
                        || state.settlement.balanceBefore.trader != state.settlement.settlementRequest.trader
                        || state.settlement.balanceBefore.chainId != state.settlement.settlementRequest.chainId
                ) {
                    revert INPUT_PARAMS_MISMATCH_SETTLEMENT();
                }

                // Don't process settlements with no balance. This handles cases where someone requests settlement
                // without having traded or deposited.
                if (state.settlement.balanceBefore.amount == 0) revert("Settlement with no balance");
            }
            // Calculate settlement fee
            (uint256 insuranceFee, uint256 stakerReward) =
                IFeeManager(address(manager)).calculateSettlementFees(state.settlement.balanceBefore.amount);
            emit SettlementFeePaid(state.settlement.balanceBefore.trader, Id.unwrap(_chainId), state.settlement.balanceBefore.asset, insuranceFee + stakerReward);
            // create an obligation to be relayed
            obligations[i] = IPortal.Obligation(
                state.settlement.balanceBefore.trader,
                state.settlement.balanceBefore.asset,
                state.settlement.balanceBefore.amount - (insuranceFee + stakerReward)
            );

            IStaking staking = IStaking(manager.staking());
            if (requiresCollateral) {
                // Convert value of settlement asset into equivalent stablecoin value based on latest Oracle price
                state.stablecoinValue = IOracle(manager.oracle()).getStablecoinValue(
                    Id.unwrap(state.settlement.balanceBefore.chainId),
                    state.settlement.balanceBefore.asset,
                    state.settlement.balanceBefore.amount
                );
                uint256 stableLockId = staking.lock(staking.stablecoin(), state.stablecoinValue);
                // Lock 15% of above as protocol token
                uint256 protocolValue = IOracle(manager.oracle()).stablecoinToProtocol(state.stablecoinValue);
                protocolValue = (protocolValue * 15e6) / 100e6;
                uint256 protocolLockId = staking.lock(staking.protocolToken(), protocolValue);

                // Associate lock Ids with state root
                lockIdStateRoot[stableLockId] = StateRootRecord(state.stateRoot, _params[i].stateRootId);
                lockIdStateRoot[protocolLockId] = StateRootRecord(state.stateRoot, _params[i].stateRootId);
                // Split settlement fee between network and insurance fund
                staking.payInsurance(
                    Id.unwrap(state.settlement.balanceBefore.chainId),
                    state.settlement.balanceBefore.asset,
                    insuranceFee
                );
                // Split staker reward between stablecoin pool and protocol token pool
                (uint256 stablePoolReward, uint256 protocolPoolReward) =
                    IFeeManager(address(manager)).calculateStakingRewards(stakerReward);
                staking.reward(
                    stableLockId,
                    Id.unwrap(state.settlement.balanceBefore.chainId),
                    state.settlement.balanceBefore.asset,
                    stablePoolReward
                );
                staking.reward(
                    protocolLockId,
                    Id.unwrap(state.settlement.balanceBefore.chainId),
                    state.settlement.balanceBefore.asset,
                    protocolPoolReward
                );
            } else {
                // No collateral required, entire settlement fee goes to insurance
                staking.payInsurance(
                    Id.unwrap(state.settlement.balanceBefore.chainId),
                    state.settlement.balanceBefore.asset,
                    insuranceFee
                );
            }

            // Mark settlement as processed
            processedSettlements[_params[i].stateRootId][state.stateRoot].add(
                Id.unwrap(_params[i].signedUpdate.stateUpdate.sequenceId)
            );
        }

        // After performing validation, locking required collateral, and distributing settlement fees,
        // relay the obligations to the asset chain.
        IProcessingChainLz(manager.relayer()).sendObligations{ value: msg.value }(
            Id.unwrap(_chainId), obligations, bytes(""), msg.sender
        );
    }

    struct RejectedDepositParams {
        StateUpdateLibrary.SignedStateUpdate signedUpdate;
        Id stateRootId;
        bytes32[] proof;
    }

    function processRejectedDeposits(
        Id _chainId,
        RejectedDepositParams[] calldata _params,
        bytes calldata adapterParams
    )
        external
        payable
    {
        bytes32[] memory depositHashes = new bytes32[](_params.length);
        for (uint256 i = 0; i < _params.length; i++) {
            bytes32 stateRoot = confirmedStateRoot[_params[i].stateRootId];
            if (stateRoot == "") revert EMPTY_STATE_ROOT();

            {
                bool valid =
                    MerkleProof.verify(_params[i].proof, stateRoot, keccak256(abi.encode(_params[i].signedUpdate)));
                if (!valid) revert INVALID_PROOF_REJECTED_DEPOSIT();

                if (_params[i].signedUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_DepositRejection) {
                    revert INVALID_STATE_UPDATE_REJECTED_DEPOSIT();
                }
            }

            StateUpdateLibrary.DepositRejection memory depositRejection =
                abi.decode(_params[i].signedUpdate.stateUpdate.structData, (StateUpdateLibrary.DepositRejection));

            // Only process deposit rejections for assets of the same chain ID.
            // This limits the final relay to a single chain.
            if (depositRejection.deposit.chainId != _chainId) {
                revert("Deposit chainId doesn't match _chainId");
            }

            // add the deposit hash to be relayed
            depositHashes[i] = keccak256(abi.encode(depositRejection.deposit));
        }

        // After performing validation, locking required collateral, and distributing settlement fees,
        // relay the obligations to the asset chain.
        IProcessingChainLz(manager.relayer()).sendDepositRejections{ value: msg.value }(
            Id.unwrap(_chainId), depositHashes, adapterParams, msg.sender
        );
    }

    struct TradeProof {
        StateUpdateLibrary.SignedStateUpdate tradeUpdate;
        bytes32[] proof;
    }

    struct TradingFeeClaim {
        uint256 epoch;
        TradeProof[] tradeProof;
    }

    /// Called by participating interface to claim trading fees from confirmed state roots
    function claimTradingFees(TradingFeeClaim[] calldata _claims) external {
        if (msg.sender != participatingInterface) revert("Only participating interface can claim trading fees");
        for (uint256 i = 0; i < _claims.length; i++) {
            // get confirmed state root for epoch
            bytes32 stateRoot = confirmedStateRoot[Id.wrap(_claims[i].epoch)];
            if (stateRoot == "") revert("Trying to claim trading fees for an epoch that is yet to be confirmed");

            for (uint256 t = 0; t < _claims[i].tradeProof.length; t++) {
                // prove trade exists in root
                bool valid = MerkleProof.verifyCalldata(
                    _claims[i].tradeProof[t].proof,
                    stateRoot,
                    keccak256(abi.encode(_claims[i].tradeProof[t].tradeUpdate))
                );
                if (!valid) revert("Invalid merkle proof for trade");

                // validate state update
                if (_claims[i].tradeProof[t].tradeUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Trade)
                {
                    revert("State update is not a trade");
                }
                StateUpdateLibrary.Trade memory trade =
                    abi.decode(_claims[i].tradeProof[t].tradeUpdate.stateUpdate.structData, (StateUpdateLibrary.Trade));

                // check that trade has not been claimed already
                if (tradeClaimed[_claims[i].tradeProof[t].tradeUpdate.stateUpdate.sequenceId]) {
                    revert("Fees for this trade have already been claimed");
                }
                // mark it as claimed
                tradeClaimed[_claims[i].tradeProof[t].tradeUpdate.stateUpdate.sequenceId] = true;

                // record amounts for each asset
                if (trade.makerFee.amount > 0) {
                    tradingFees[trade.makerFee.chainId][trade.makerFee.asset] += trade.makerFee.amount;
                }
                if (trade.takerFee.amount > 0) {
                    tradingFees[trade.takerFee.chainId][trade.takerFee.asset] += trade.takerFee.amount;
                }
            }
        }
    }

    /// Called by participating interface to relay trading fees to the chain where the assets can be withdrawn
    function relayTradingFees(
        uint256 _chainId,
        address[] calldata _assets,
        bytes calldata _adapterParans
    )
        external
        payable
    {
        if (msg.sender != participatingInterface) revert("Only participating interface can claim trading fees");
        IPortal.Obligation[] memory obligations = new IPortal.Obligation[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            if (tradingFees[Id.wrap(_chainId)][_assets[i]] == 0) revert("No trading fees for this asset");
            obligations[i] =
                IPortal.Obligation(participatingInterface, _assets[i], tradingFees[Id.wrap(_chainId)][_assets[i]]);
            tradingFees[Id.wrap(_chainId)][_assets[i]] = 0;
        }
        IProcessingChainLz(manager.relayer()).sendObligations{ value: msg.value }(
            _chainId, obligations, _adapterParans, msg.sender
        );
    }

    function markFraudulent(uint256 _epoch) external {
        if (msg.sender != manager.fraudEngine()) revert();
        fraudulent[Id.wrap(_epoch)][proposedStateRoot[Id.wrap(_epoch)]] = true;
    }

    function isFraudulentLockId(uint256 _lockId) external view returns (bool) {
        StateRootRecord memory r = lockIdStateRoot[_lockId];
        return fraudulent[r.epoch][r.stateRoot];
    }

    function isConfirmedLockId(uint256 _lockId) external view returns (bool) {
        StateRootRecord memory r = lockIdStateRoot[_lockId];
        return confirmedStateRoot[r.epoch] == r.stateRoot;
    }

    function getConfirmedStateRoot(uint256 _epoch) external view returns (bytes32 root) {
        root = confirmedStateRoot[Id.wrap(_epoch)];
        if (root == "") revert EPOCH_NOT_CONFIRMED();
    }

    function getProposedStateRoot(uint256 _epoch) external view returns (bytes32 root) {
        root = proposedStateRoot[Id.wrap(_epoch)];
        if (root == "") revert();
    }

    function getCurrentEpoch() external view returns (uint256) {
        return Id.unwrap(epoch);
    }
}
