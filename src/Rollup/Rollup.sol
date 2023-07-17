// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IRollup.sol";
import "../CrossChain/LayerZero/IProcessingChainLz.sol";
import "../Portal/IPortal.sol";
import "../Manager/IBaseManager.sol";
import "../Manager/IFeeManager.sol";
import "../Staking/IStaking.sol";
import "../StateUpdateLibrary.sol";
import "../util/Id.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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

    IBaseManager internal immutable manager;
    address internal immutable participatingInterface;
    uint256 public constant CONFIRMATION_BLOCKS = 50_000;

    // For compatability with Tacen Alpha

    event ObligationsWritten(Id id, address requester, address token, uint256 cleared);

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IBaseManager(_manager);
    }

    function proposeStateRoot(bytes32 _stateRoot) external {
        if (!manager.isValidator(msg.sender)) revert CALLER_NOT_VALIDATOR();
        if (_stateRoot == "") revert("Proposed empty state root");
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
        if (stateRoot == "") revert("Trying to confirm an empty state root");
        uint256 blockNumber = proposalBlock[stateRoot];

        if (block.number < blockNumber + CONFIRMATION_BLOCKS) revert("Proposed state root has not passed fraud period");
        if (fraudulent[lastConfirmedEpoch][stateRoot]) revert("Trying to confirm a fraudulent state root");

        confirmedStateRoot[lastConfirmedEpoch] = stateRoot;
    }

    /**
     * Called by anyone to complete a settlement.
     *
     * TODO: Currently requires settlements to be processed sequentially. Remove this restriction and instead track
     * which settlements have been processed.
     */
    struct SettlementParams {
        StateUpdateLibrary.SignedStateUpdate signedUpdate;
        Id stateRootId;
        bytes32[] proof;
    }

    function processSettlements(Id _chainId, SettlementParams[] calldata _params) external payable {
        IPortal.Obligation[] memory obligations = new IPortal.Obligation[](_params.length);
        for (uint256 i = 0; i < _params.length; i++) {
            bool requiresCollateral = false;
            bytes32 stateRoot = confirmedStateRoot[_params[i].stateRootId];
            if (stateRoot == 0) {
                requiresCollateral = true;
                stateRoot = proposedStateRoot[_params[i].stateRootId];
                if (stateRoot == 0) revert EMPTY_STATE_ROOT();
            }

            bool valid =
                MerkleProof.verifyCalldata(_params[i].proof, stateRoot, keccak256(abi.encode(_params[i].signedUpdate)));
            if (!valid) revert INVALID_PROOF_SETTLEMENT();

            if (_params[i].signedUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) {
                revert INVALID_STATE_UPDATE_SETTLEMENT();
            }

            StateUpdateLibrary.Settlement memory settlement =
                abi.decode(_params[i].signedUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));

            StateUpdateLibrary.SettlementRequest memory settlementRequest = settlement.settlementRequest;

            // Only process settlements for assets of the same chain ID
            if (settlementRequest.chainId != _chainId) revert("Settlement request chainId doesn't match _chainId");

            // Validate the balance in the settlement and the trader/asset of the settlement request
            if (
                settlement.balanceBefore.asset != settlementRequest.asset
                    || settlement.balanceBefore.trader != settlementRequest.trader
                    || settlement.balanceBefore.chainId != settlementRequest.chainId
            ) {
                revert INPUT_PARAMS_MISMATCH_SETTLEMENT();
            }

            // Calculate settlement fee
            (uint256 insuranceFee, uint256 stakerReward) =
                IFeeManager(address(manager)).calculateSettlementFees(settlement.balanceBefore.amount);
            // TODO: obligations need to be relayed from processing chain to other chains
            // create an obligation to be relayed
            obligations[i] = IPortal.Obligation(
                settlement.balanceBefore.trader, settlement.balanceBefore.asset, settlement.balanceBefore.amount - (insuranceFee + stakerReward)
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

        // After performing validation, locking required collateral, and distributing settlement fees,
        // relay the obligations to the asset chain.
        IProcessingChainLz(IBaseManager(address(manager)).relayer()).sendObligations{ value: msg.value }(
            Id.unwrap(_chainId), obligations, bytes(""), msg.sender
        );
    }

    // Confirms a state root and processes a settlement in a single transaction.
    // Used for testing validator's ability to construct state roots, will be removed.
    function submitSettlement(
        bytes32 _stateRoot,
        StateUpdateLibrary.SignedStateUpdate calldata _signedUpdate,
        bytes32[] calldata _proof
    )
        external payable
    {
        epoch = epoch.increment();
        lastConfirmedEpoch = lastConfirmedEpoch.increment();

        confirmedStateRoot[lastConfirmedEpoch] = _stateRoot;
    if (_signedUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) {
                revert INVALID_STATE_UPDATE_SETTLEMENT();
            }

            StateUpdateLibrary.Settlement memory settlement =
                abi.decode(_signedUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));
                SettlementParams[] memory params = new SettlementParams[](1);
                params[0]= SettlementParams(_signedUpdate, lastConfirmedEpoch, _proof);
        _processSettlements(settlement.balanceBefore.chainId, params);
    }

  function _processSettlements(Id _chainId, SettlementParams[] memory _params) internal {
        IPortal.Obligation[] memory obligations = new IPortal.Obligation[](_params.length);
        for (uint256 i = 0; i < _params.length; i++) {
            bool requiresCollateral = false;
            bytes32 stateRoot = confirmedStateRoot[_params[i].stateRootId];
            if (stateRoot == 0) {
                requiresCollateral = true;
                stateRoot = proposedStateRoot[_params[i].stateRootId];
                if (stateRoot == 0) revert EMPTY_STATE_ROOT();
            }

            bool valid =
                MerkleProof.verify(_params[i].proof, stateRoot, keccak256(abi.encode(_params[i].signedUpdate)));
            if (!valid) revert INVALID_PROOF_SETTLEMENT();

            if (_params[i].signedUpdate.stateUpdate.typeIdentifier != StateUpdateLibrary.TYPE_ID_Settlement) {
                revert INVALID_STATE_UPDATE_SETTLEMENT();
            }

            StateUpdateLibrary.Settlement memory settlement =
                abi.decode(_params[i].signedUpdate.stateUpdate.structData, (StateUpdateLibrary.Settlement));

            StateUpdateLibrary.SettlementRequest memory settlementRequest = settlement.settlementRequest;

            // Only process settlements for assets of the same chain ID
            if (settlementRequest.chainId != _chainId) revert("Settlement request chainId doesn't match _chainId");

            // Validate the balance in the settlement and the trader/asset of the settlement request
            if (
                settlement.balanceBefore.asset != settlementRequest.asset
                    || settlement.balanceBefore.trader != settlementRequest.trader
                    || settlement.balanceBefore.chainId != settlementRequest.chainId
            ) {
                revert INPUT_PARAMS_MISMATCH_SETTLEMENT();
            }

            // Calculate settlement fee
            (uint256 insuranceFee, uint256 stakerReward) =
                IFeeManager(address(manager)).calculateSettlementFees(settlement.balanceBefore.amount);
            // TODO: obligations need to be relayed from processing chain to other chains
            // create an obligation to be relayed
            obligations[i] = IPortal.Obligation(
                settlement.balanceBefore.trader, settlement.balanceBefore.asset, settlement.balanceBefore.amount - (insuranceFee + stakerReward)
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

        // After performing validation, locking required collateral, and distributing settlement fees,
        // relay the obligations to the asset chain.
        IProcessingChainLz(IBaseManager(address(manager)).relayer()).sendObligations{ value: msg.value }(
            Id.unwrap(_chainId), obligations, bytes(""), msg.sender
        );
    } 

    // Maps sequnce ID of state update to whether or not its fee(s) have been claimed by the participating interface
    mapping(Id => bool) internal tradeClaimed;
    // Maps chain ID to asset address to amount that has been claimed as fees and is awaiting relay
    mapping(Id => mapping(address => uint256)) internal tradingFees;

    struct TradeProof {
        StateUpdateLibrary.SignedStateUpdate tradeUpdate;
        bytes32[] proof;
    }

    struct TradingFeeClaim {
        uint256 epoch;
        TradeProof[] tradeProof;
    }
    // Called by participating interface to claim trading fees from confirmed epochs

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

    // Called by participating interface to relay trading fees to the chain where the assets can be withdrawn
    function relayTradingFees(uint256 _chainId, address[] calldata _assets) external payable {
        if (msg.sender != participatingInterface) revert("Only participating interface can claim trading fees");
        IPortal.Obligation[] memory obligations = new IPortal.Obligation[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            if (tradingFees[Id.wrap(_chainId)][_assets[i]] == 0) revert();
            obligations[i] =
                IPortal.Obligation(participatingInterface, _assets[i], tradingFees[Id.wrap(_chainId)][_assets[i]]);
            tradingFees[Id.wrap(_chainId)][_assets[i]] = 0;
        }
        IProcessingChainLz(IBaseManager(address(manager)).relayer()).sendObligations{ value: msg.value }(
            _chainId, obligations, bytes(""), msg.sender
        );
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
