// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IRollup.sol";
import "./ICollateral.sol";
import "../Portal/IPortal.sol";
import "../Manager/IManager.sol";
import "../Manager/IBaseManager.sol";
import "../Manager/IFeeManager.sol";
import "../Staking/IStaking.sol";
import "../StateUpdateLibrary.sol";
import "../util/Id.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * The Rollup contract accepts settlement data reports from validators.
 */
contract Rollup is IRollup {
    using IdLib for Id;

    Id public epoch = ID_ONE;
    Id public lastConfirmedEpoch = ID_ZERO;
    mapping(Id => bytes32) public proposedStateRoot;
    mapping(bytes32 => uint256) public proposalBlock;
    mapping(bytes32 => Id) public proposalLockId;
    mapping(Id => mapping(bytes32 => bool)) public fraudulent;
    mapping(Id => bytes32) public confirmedStateRoot;
    mapping(uint256 => mapping(uint256 => bool)) public processedSettlements;

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
    error CALLER_NOT_PORTAL(address sender, address expected);

    IManager internal immutable manager;
    address internal immutable participatingInterface;
    uint256 public constant CONFIRMATION_BLOCKS = 50_000;

    // For compatability with Tacen Alpha
    Id public lastSettlementIdProcessed = ID_ONE;
    Id public nextRequestId = Id.wrap(2);

    event ObligationsWritten(Id id, address requester, address token, uint256 cleared);

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IManager(_manager);
    }

    function proposeStateRoot(bytes32 _stateRoot) external {
        if (!manager.isValidator(msg.sender)) revert CALLER_NOT_VALIDATOR();
        IStaking staking = IStaking(IBaseManager(address(manager)).collateral());
        Id lockId = Id.wrap(staking.lock(staking.protocolToken(), staking.ROOT_PROPOSAL_LOCK_AMOUNT()));
        // TODO: burn some of the protocol token

        proposedStateRoot[epoch] = _stateRoot;
        proposalBlock[_stateRoot] = block.number;
        proposalLockId[_stateRoot] = lockId;
        epoch = epoch.increment();
    }

    function confirmStateRoot() external {
        lastConfirmedEpoch = lastConfirmedEpoch.increment();

        bytes32 stateRoot = proposedStateRoot[lastConfirmedEpoch];
        uint256 blockNumber = proposalBlock[stateRoot];

        if (block.number < blockNumber + CONFIRMATION_BLOCKS) revert();
        if (fraudulent[lastConfirmedEpoch][stateRoot]) revert();

        confirmedStateRoot[lastConfirmedEpoch] = stateRoot;
    }

    /**
     * Called by anyone to complete a settlement.
     * 
     * TODO: Currently requires settlements to be processed sequentially. Remove this restriction and instead track which settlements have been processed.
     */
    function processSettlement(
        StateUpdateLibrary.SignedStateUpdate calldata _signedUpdate,
        Id _stateRootId,
        bytes32[] calldata _proof
    )
        external
    {
        bool requiresCollateral = false;
        bytes32 stateRoot = confirmedStateRoot[_stateRootId];
        if (stateRoot == 0) {
            requiresCollateral = true;
            stateRoot = proposedStateRoot[_stateRootId];
            if (stateRoot == 0) revert EMPTY_STATE_ROOT();
        }

        bool valid = MerkleProof.verifyCalldata(_proof, stateRoot, keccak256(abi.encode(_signedUpdate)));
        if (!valid) revert INVALID_PROOF_SETTLEMENT();

        if (_signedUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) {
            revert INVALID_STATE_UPDATE_SETTLEMENT();
        }

        StateUpdateLibrary.Settlement memory settlement =
            abi.decode(_signedUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));

        StateUpdateLibrary.SettlementRequest memory settlementRequest = settlement.settlementRequest;

        if (settlementRequest.settlementId != lastSettlementIdProcessed.increment()) {
            revert INVALID_SEQUENCE_SETTLEMENT();
        }

        if (
            !IPortal(manager.portal()).isValidSettlementRequest({
                chainSequenceId: Id.unwrap(settlementRequest.chainSequenceId),
                settlementHash: keccak256(abi.encode(settlementRequest))
            }) || settlementRequest.chainId != Id.wrap(block.chainid)
        ) revert INVALID_REQUEST_SETTLEMENT();

        if (
            settlement.balanceBefore.asset != settlementRequest.asset
                || settlement.balanceBefore.trader != settlementRequest.trader
                || settlement.balanceBefore.chainId != Id.wrap(block.chainid)
        ) {
            revert INPUT_PARAMS_MISMATCH_SETTLEMENT();
        }

        // Calculate settlement fee
        (uint256 insuranceFee, uint256 stakerReward) =
            IFeeManager(address(manager)).calculateSettlementFees(settlement.balanceBefore.amount);
        // TODO: obligations need to be relayed from processing chain to other chains
        IPortal(manager.portal()).writeObligation({
            token: settlement.balanceBefore.asset,
            recipient: settlement.balanceBefore.trader,
            amount: settlement.balanceBefore.amount - (insuranceFee + stakerReward)
        });

        lastSettlementIdProcessed = lastSettlementIdProcessed.increment();

        emit ObligationsWritten(
            settlementRequest.settlementId,
            settlementRequest.trader,
            settlementRequest.asset,
            IPortal(manager.portal()).getAvailableBalance(settlementRequest.trader, settlementRequest.asset)
        );

        IStaking staking = IStaking(IBaseManager(address(manager)).collateral());
        if (requiresCollateral) {
            // TODO: Query oracle for price of settlement asset in stablecoin token
            // For now:
            // We assume balance token is 18 decimals of precision, convert to 6 decimals by dividing by 1e12
            // Lock 1:1 requested asset
            uint256 stableLockId = staking.lock(staking.stablecoin(), settlement.balanceBefore.amount / 1e12);
            // Lock 15% of above as protocol token
            uint256 protocolLockId = staking.lock(
                staking.protocolToken(), staking.stablecoinToProtocol(settlement.balanceBefore.amount / 1e12)
            );

            // Split settlement fee between network and insurance fund
            staking.payInsurance(
                Id.unwrap(settlement.balanceBefore.chainId), settlement.balanceBefore.asset, insuranceFee
            );
            // Split staker reward between stablecoin pool and protocol token pool
            (uint256 stablePoolReward, uint256 protocolPoolReward) =
                IFeeManager(address(manager)).calculateStakingRewards(stakerReward);
            staking.reward(
                stableLockId,
                Id.unwrap(settlement.balanceBefore.chainId),
                settlement.balanceBefore.asset,
                stablePoolReward
            );
            staking.reward(
                protocolLockId,
                Id.unwrap(settlement.balanceBefore.chainId),
                settlement.balanceBefore.asset,
                protocolPoolReward
            );
        } else {
            // No collateral required, entire settlement fee goes to insurance
            staking.payInsurance(
                Id.unwrap(settlement.balanceBefore.chainId), settlement.balanceBefore.asset, insuranceFee
            );
        }
    }

    // Confirms a state root and processes a settlement in a single transaction.
    // Used for testing validator's ability to construct state roots, will be removed.
    function submitSettlement(
        bytes32 _stateRoot,
        StateUpdateLibrary.SignedStateUpdate calldata _signedUpdate,
        bytes32[] calldata _proof
    )
        external
    {
        epoch = epoch.increment();
        lastConfirmedEpoch = lastConfirmedEpoch.increment();

        confirmedStateRoot[lastConfirmedEpoch] = _stateRoot;

        _processSettlement(_signedUpdate, lastConfirmedEpoch, _proof);
    }

    function _processSettlement(
        StateUpdateLibrary.SignedStateUpdate calldata _signedUpdate,
        Id _stateRootId,
        bytes32[] calldata _proof
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

        StateUpdateLibrary.Settlement memory settlement =
            abi.decode(_signedUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));

        StateUpdateLibrary.SettlementRequest memory settlementRequest = settlement.settlementRequest;

        if (settlementRequest.settlementId != lastSettlementIdProcessed.increment()) {
            revert INVALID_SEQUENCE_SETTLEMENT();
        }

        if (
            !IPortal(manager.portal()).isValidSettlementRequest({
                chainSequenceId: Id.unwrap(settlementRequest.chainSequenceId),
                settlementHash: keccak256(abi.encode(settlementRequest))
            }) || settlementRequest.chainId != Id.wrap(block.chainid)
        ) revert INVALID_REQUEST_SETTLEMENT();

        if (
            settlement.balanceBefore.asset != settlementRequest.asset
                || settlement.balanceBefore.trader != settlementRequest.trader
                || settlement.balanceBefore.chainId != Id.wrap(block.chainid)
        ) {
            revert INPUT_PARAMS_MISMATCH_SETTLEMENT();
        }

        IPortal(manager.portal()).writeObligation({
            token: settlement.balanceBefore.asset,
            recipient: settlement.balanceBefore.trader,
            amount: settlement.balanceBefore.amount
        });

        lastSettlementIdProcessed = lastSettlementIdProcessed.increment();
        // TODO: query oracle for price of requested asset in USD
        // convert total amount of requested asset to USD
        // calculate corresponding protocol token amount
        // call Collateral contract to lock stablecoin and protocol token

        // For now:
        // Lock 1:1 requested asset
        // Lock 15% of above as protocol token
        // Burn 0.05% of above as protocol token
        emit ObligationsWritten(
            settlementRequest.settlementId,
            settlementRequest.trader,
            settlementRequest.asset,
            IPortal(manager.portal()).getAvailableBalance(settlementRequest.trader, settlementRequest.asset)
        );
    }

    function requestSettlement(address, address) external returns (uint256) {
        if (msg.sender != manager.portal()) revert CALLER_NOT_PORTAL(msg.sender, manager.portal());
        nextRequestId = nextRequestId.increment();
        unchecked {
            return Id.unwrap(nextRequestId) - 1;
        }
    }

    function markFraudulent(uint256 _epoch) external {
        if (msg.sender != IBaseManager(address(manager)).fraudEngine()) revert();
        // if (fraudulent[proposedStateRoot[_epoch]]) revert();
        fraudulent[Id.wrap(_epoch)][proposedStateRoot[Id.wrap(_epoch)]] = true;
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
