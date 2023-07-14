// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IStaking.sol";
import "../StateUpdateLibrary.sol";
import "../Manager/IManager.sol";
import "../Manager/IBaseManager.sol";
import "../Rollup/IRollup.sol";
import "../Oracle/IOracle.sol";
import "../util/Id.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/utils/structs/EnumerableSet.sol";

struct Reward {
    address asset;
    uint256 amount;
}

interface IRewardsRelayer {
    function relayRewards(uint256 _chainId, Reward[] calldata _rewards) external;
}

contract Staking is IStaking {
    using IdLib for Id;
    using EnumerableSet for EnumerableSet.UintSet;

    error INSUFFICIENT_COLLATERAL(uint256 amountToLock, uint256 amountLeft);

    // TIME CONSTANTS
    // Minimum number of blocks for which funds must be locked
    uint256 public constant PERIOD_LENGTH = 5_184_000; // ~ 60 days on Arbitrum Nova
    // Number of blocks before end of period at which locking assets from a tranche is no longer possible.
    // This should be >= the length of the fraud period.
    uint256 public constant LOCKING_CUTOFF = 345_600; // ~ 4 days on Arbitrum Nova
    // Number of blocks before end of period at which depositing assets into a tranche is no longer possible.
    uint256 public constant DEPOSIT_CUTOFF = 345_600; // ~ 4 days on Arbitrum Nova
    // How many staking periods are available at one time
    uint256 public constant ACTIVE_PERIODS = 3;

    // STAKING AMOUNT CONSTANTS
    // Amount of protocol token required to lock when proposing a state root
    uint256 public constant ROOT_PROPOSAL_LOCK_AMOUNT = 10_000e18;

    struct DepositRecord {
        address staker;
        address asset;
        // amount staked
        uint256 amount;
        // block number at which deposit was made
        uint256 blockNumber;
        // block number when deposit becomes unlocked
        uint256 unlockTime;
    }

    Id public currentDepositId = ID_ZERO;
    Id public currentLockId = ID_ZERO;
    mapping(uint256 => DepositRecord) deposits;
    mapping(address => mapping(address => EnumerableSet.UintSet)) internal userDeposits;
    // depositId => lockId => chainId => rewardAsset => claimed
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(address => uint256)))) claimedRewards;

    struct LockRecord {
        // amount of the asset that was locked
        uint256 amountLocked;
        // total amount of the asset deposited in active tranches
        uint256 totalAvailable;
        // block number at which the lock occurred
        uint256 blockNumber;
    }
    // Lock ID to collateral asset to record generated when an asset is locked

    mapping(uint256 => mapping(address => LockRecord)) internal locks;
    // Lock ID to reward asset chain ID to address to amount earned in rewards
    // Value is total earned for all stakers with assets in tranches that were eligible
    // use as collateral at time of lock.
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) internal rewards;
    // Used to sum up rewards for a single staker across multiple deposits, locks, and assets
    mapping(address => mapping(uint256 => mapping(address => uint256))) internal toClaim;
    mapping(uint256 => mapping(address => uint256)) internal insuranceFees;

    struct TotalAmount {
        uint256 total;
        uint256 locked;
    }

    // Maps ID of staking period to amounts deposited and locked
    mapping(address => mapping(uint256 => TotalAmount)) totals;

    IManager immutable manager;
    address public stablecoin;
    address public protocolToken;

    constructor(address _manager, address _stablecoin, address _protocolToken) {
        manager = IManager(_manager);
        stablecoin = _stablecoin;
        protocolToken = _protocolToken;
    }

    function stake(address _asset, uint256 _amount, uint256 _unlockTime) external {
        if (!(_asset == stablecoin || _asset == protocolToken)) revert();
        require(IERC20(_asset).transferFrom(msg.sender, address(this), _amount));

        if (_unlockTime % PERIOD_LENGTH != 0) revert();
        if (block.number >= _unlockTime - DEPOSIT_CUTOFF) revert();

        deposits[Id.unwrap(currentDepositId)] = DepositRecord(msg.sender, _asset, _amount, block.number, _unlockTime);
        userDeposits[msg.sender][_asset].add(Id.unwrap(currentDepositId));
        totals[_asset][_unlockTime].total += _amount;

        currentDepositId = currentDepositId.increment();
    }

    function lock(address _asset, uint256 _amountToLock) external returns(uint256) {
        if (msg.sender != manager.rollup()) revert("Only rollup can lock");
        if (_amountToLock == 0) revert("Amount to lock must not be 0");
        if (!(_asset == stablecoin || _asset == protocolToken)) revert("Can only lock stablecoin or protocolToken");

        uint256[ACTIVE_PERIODS] memory tranches = getActiveTranches();
        uint256 totalAvailable = 0;
        uint256 amountLeft = _amountToLock;
        for (uint256 i = 0; i < tranches.length; i++) {
            if (amountLeft == 0) break;
            // get balance of asset in tranche
            uint256 available = totals[_asset][tranches[i]].total - totals[_asset][tranches[i]].locked;
            if (available == 0) continue;
            totalAvailable += available;
            if (available <= amountLeft) {
                amountLeft -= available;
                // set available in tranche to 0
                totals[_asset][tranches[i]].locked += available;
            } else {
                // set available in tranche to: available - _amountToLock
                totals[_asset][tranches[i]].locked += amountLeft;
                amountLeft = 0;
            }
        }
        if (amountLeft > 0) revert INSUFFICIENT_COLLATERAL({amountToLock: _amountToLock, amountLeft: amountLeft});

        locks[Id.unwrap(currentLockId)][_asset] = LockRecord(_amountToLock, totalAvailable, block.number);
        currentLockId = currentLockId.increment();
        // TODO: emit an event
        return Id.unwrap(currentLockId) - 1;
    }

    function unlock() external { }

    function reward(uint256 _lockId, uint256 _chainId, address _asset, uint256 _amount) external {
        if (msg.sender != manager.rollup()) revert();
        rewards[_lockId][_chainId][_asset] += _amount;
        // TODO: emit event
    }

    // Called by rollup contract to delegate a portion of settlement fee to the insurance fund
    function payInsurance(uint256 _chainId, address _asset, uint256 _amount) external {
        if (msg.sender != manager.rollup()) revert();
        insuranceFees[_chainId][_asset] += _amount;
    }

    struct ClaimParams {
        uint256[] lockId;
        uint256[] depositId;
        uint256 rewardChainId;
        address[] rewardAsset;
    }

    // Called by the staker to claim rewards and relay them to the blockchain where the assets are deposited.
    function claim(ClaimParams calldata _params) external {
        for (uint256 d = 0; d < _params.depositId.length; d++) {
            // get deposit record
            uint256 depositId = _params.depositId[d];
            DepositRecord storage depositRecord = deposits[depositId];
            // deposit record must belong to sender
            if (depositRecord.staker != msg.sender) revert();
            for (uint256 l = 0; l < _params.lockId.length; l++) {
                uint256 lockId = _params.lockId[l];
                // get lock record
                LockRecord storage lockRecord = locks[lockId][depositRecord.asset];

                // Deposit should be eligible for the given lock record
                if (
                    depositRecord.blockNumber >= lockRecord.blockNumber
                        || lockRecord.blockNumber > depositRecord.unlockTime - LOCKING_CUTOFF
                ) continue;
                for (uint256 i = 0; i < _params.rewardAsset.length; i++) {
                    address rewardAsset = _params.rewardAsset[i];
                    // get rewards for lock record
                    uint256 totalRewards = rewards[lockId][_params.rewardChainId][rewardAsset];
                    // calculate how much goes to deposit record
                    // totalReward * (deposited / totalDeposited)
                    uint256 claimable = (totalRewards * depositRecord.amount * 1e5) / (lockRecord.totalAvailable * 1e5);
                    // get how much has already been claimed
                    uint256 claimed = claimedRewards[depositId][lockId][_params.rewardChainId][rewardAsset];
                    // check if there's anything that can be claimed
                    if (claimed < claimable) {
                        uint256 amountToClaim = claimable - claimed;
                        // update claimed amount
                        claimedRewards[depositId][lockId][_params.rewardChainId][rewardAsset] += amountToClaim;
                        // add to amount of asset that will be relayed
                        toClaim[msg.sender][_params.rewardChainId][rewardAsset] += amountToClaim;
                    }
                }
            }
        }

        Reward[] memory rewardsToRelay = new Reward[](_params.rewardAsset.length);
        for (uint256 i = 0; i < _params.rewardAsset.length; i++) {
            uint256 amountToClaim = toClaim[msg.sender][_params.rewardChainId][_params.rewardAsset[i]];
            if (amountToClaim == 0) revert();
            rewardsToRelay[i] = Reward(_params.rewardAsset[i], amountToClaim);
            // Set to 0 so it can't be used again
            toClaim[msg.sender][_params.rewardChainId][_params.rewardAsset[i]] = 0;
        }
        // relay record based on chain ID
        // TODO: send rewardsToRelay to contract responsible for relaying from processing chain to _rewardChainId
        IRewardsRelayer(IBaseManager(address(manager)).relayer()).relayRewards(_params.rewardChainId, rewardsToRelay);
    }

    // Returns block numbers of periods that can be staked into
    // Block number represents time at which all deposits for that period can be withdrawn
    // Can be used to determine the total available + locked collateral that's eligible for reward
    function getActiveTranches() public view returns (uint256[ACTIVE_PERIODS] memory tranches) {
        // Number of blocks passed for the current period
        // If 0, then the current block number is the exact beginning of a new period
        uint256 r = block.number % PERIOD_LENGTH;
        // Start time of the earliest period
        uint256 current = block.number - (r > 0 ? r : 0);
        // If past the deposit cutoff, then the current period is closed and the subsequent is earliest.
        if (r >= DEPOSIT_CUTOFF) {
            current += PERIOD_LENGTH;
        }
        for (uint256 i = 0; i < ACTIVE_PERIODS; i++) {
            tranches[i] = current + (PERIOD_LENGTH * i);
        }
    }

    // Returns amount of protocol token required to stake alongside the specified number of stablecoin tokens
    function stablecoinToProtocol(uint256 _stablecoinAmount) public pure returns (uint256) {
        // TODO: call oracle to get price of protocol token in stablecoin token
        // Convert stablecoin amount to protocol token amount (assuming 1 protocol token costs $0.30)
        // Converts to 18 decimal precision to match protocol token
        uint256 protocolAmount = ((_stablecoinAmount * 30e5) / 100e5) * 1e12;
        // 15% of the amount above is required to be staked as protocol token
        return (protocolAmount * 15e5) / 100e5;
    }
}
