// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IStaking.sol";
import "../StateUpdateLibrary.sol";
import "../Portal/IPortal.sol";
import "../CrossChain/LayerZero/IProcessingChainLz.sol";
import "../Manager/ProcessingChain/IProcessingChainManager.sol";
import "../Rollup/IRollup.sol";
import "../Oracle/IOracle.sol";
import "../util/Id.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// Deployed on the Processing chain. Allows stakers to deposit the stablecoin or protocol token into one of three
/// active tranches with a pre-defined unlock date. Until the unlock date is reached, the locked tokens can be used as
/// collateral by the validator when processing settlements.
contract Staking is IStaking {
    using IdLib for Id;
    using EnumerableSet for EnumerableSet.UintSet;

    error INSUFFICIENT_COLLATERAL(uint256 amountToLock, uint256 amountLeft);

    // TIME CONSTANTS
    // Minimum number of blocks for which funds must be locked
    uint256 public constant PERIOD_LENGTH = 28_800 * 15; // About 60 days on Ethereum
    // How many staking periods are available at one time
    uint256 public constant ACTIVE_PERIODS = 3;

    struct DepositRecord {
        address staker;
        address asset;
        // amount staked
        uint256 amount;
        // block number at which deposit was made
        uint256 blockNumber;
        // block number when deposit becomes unlocked
        uint256 unlockTime;
        uint256 withdrawn;
    }

    Id public currentDepositId = ID_ZERO;
    Id public currentLockId = ID_ZERO;
    Id public nextIdToUnlock = ID_ZERO;
    mapping(uint256 => DepositRecord) public deposits;
    mapping(address => EnumerableSet.UintSet) internal userDeposits;
    // depositId => lockId => chainId => rewardAsset => claimed
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(address => uint256)))) claimedRewards;
    // asset address to amount staked
    mapping(address => uint256) public totalStaked;
    // staker address to asset address to amount staked
    mapping(address => mapping(address => uint256)) public individualStaked;

    struct LockRecord {
        // amount of the asset that was locked
        uint256 amountLocked;
        // total amount of the asset deposited in active tranches
        uint256 totalAvailable;
        // block number at which the lock occurred
        uint256 blockNumber;
        address asset;
    }
    // Lock ID to collateral asset to record generated when an asset is locked

    // mapping(uint256 => mapping(address => LockRecord)) public locks;
    mapping(uint256 => LockRecord) public locks;
    // Lock ID to reward asset chain ID to address to amount earned in rewards
    // Value is total earned for all stakers with assets in tranches that were eligible
    // use as collateral at time of lock.
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) internal rewards;
    // Used to sum up rewards for a single staker across multiple deposits, locks, and assets
    mapping(address => mapping(uint256 => mapping(address => uint256))) internal toClaim;
    mapping(uint256 => mapping(address => uint256)) internal insuranceFees;
    // Maps Lock ID to amount slashed
    mapping(uint256 => uint256) amountSlashed;

    struct TotalAmount {
        uint256 total;
        uint256 locked;
    }

    // Maps ID of staking period to amounts deposited and locked
    mapping(address => mapping(uint256 => TotalAmount)) totals;

    IProcessingChainManager immutable manager;
    address public stablecoin;
    address public protocolToken;

    constructor(address _manager, address _stablecoin, address _protocolToken) {
        manager = IProcessingChainManager(_manager);
        stablecoin = _stablecoin;
        protocolToken = _protocolToken;
    }

    uint256 public constant minimumStablecoinStake = 200e6;
    uint256 public constant minimumProtocolStake = 200e18;

    function stake(address _asset, uint256 _amount, uint256 _unlockTime) public {
        if (!(_asset == stablecoin || _asset == protocolToken)) revert("Invalid asset");
        require(IERC20(_asset).transferFrom(msg.sender, address(this), _amount), "Failed to transfer token");

        if (_unlockTime % PERIOD_LENGTH != 0) revert("Invalid unlock time");
        if (block.number >= _unlockTime - manager.fraudPeriod()) revert("Can no longer stake into this tranche");

        deposits[Id.unwrap(currentDepositId)] = DepositRecord(msg.sender, _asset, _amount, block.number, _unlockTime, 0);
        userDeposits[msg.sender].add(Id.unwrap(currentDepositId));
        totals[_asset][_unlockTime].total += _amount;
        totalStaked[_asset] += _amount;
        individualStaked[msg.sender][_asset] += _amount;

        currentDepositId = currentDepositId.increment();
    }

    function withdraw(uint256[] calldata _depositIds) external {
        uint256 stablecoinAmount = 0;
        uint256 protocolTokenAmount = 0;
        for (uint256 i = 0; i < _depositIds.length; i++) {
            DepositRecord storage depositRecord = deposits[_depositIds[i]];
            if (depositRecord.staker != msg.sender) revert("Sender must match staker of deposit record");
            if (depositRecord.unlockTime > block.number) revert("Unlock date for deposit record has not been reached");
            if (depositRecord.withdrawn == depositRecord.amount) revert("Deposit already withdrawn");
            // get totals for this tranche and calculate how much of this amount is available for withdraw
            TotalAmount memory total = totals[depositRecord.asset][depositRecord.unlockTime];
            uint256 unlocked = ((total.total - total.locked) * depositRecord.amount) / total.total;
            uint256 available = unlocked - depositRecord.withdrawn;
            if (available == 0) revert("No available amount for this deposit id");
            depositRecord.withdrawn += available;
            if (depositRecord.asset == stablecoin) {
                stablecoinAmount += available;
            } else if (depositRecord.asset == protocolToken) {
                protocolTokenAmount += available;
            } else {
                revert("Should not be a deposit record for assets beside stablecoin or protocolToken");
            }
        }
        if (stablecoinAmount > 0) {
            require(IERC20(stablecoin).transfer(msg.sender, stablecoinAmount));
            totalStaked[stablecoin] -= stablecoinAmount;
            individualStaked[msg.sender][stablecoin] -= stablecoinAmount;
        }
        if (protocolTokenAmount > 0) {
            require(IERC20(protocolToken).transfer(msg.sender, protocolTokenAmount));
            totalStaked[protocolToken] -= stablecoinAmount;
            individualStaked[msg.sender][protocolToken] -= stablecoinAmount;
        }
    }

    function lock(address _asset, uint256 _amountToLock) external returns (uint256) {
        if (msg.sender != manager.rollup()) revert("Only rollup can lock");
        if (_amountToLock == 0) revert("Amount to lock must not be 0");
        if (!(_asset == stablecoin || _asset == protocolToken)) revert("Can only lock stablecoin or protocolToken");

        uint256[ACTIVE_PERIODS] memory tranches = getActiveTranches();
        uint256 totalAvailable = 0;
        uint256 amountLeft = _amountToLock;
        for (uint256 i = 0; i < tranches.length; i++) {
            // get balance of asset in tranche
            uint256 available = totals[_asset][tranches[i]].total - totals[_asset][tranches[i]].locked;
            if (available == 0) continue;
            totalAvailable += available;
            if (amountLeft == 0) continue;
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
        if (amountLeft > 0) revert INSUFFICIENT_COLLATERAL({ amountToLock: _amountToLock, amountLeft: amountLeft });

        locks[Id.unwrap(currentLockId)] = LockRecord(_amountToLock, totalAvailable, block.number, _asset);
        currentLockId = currentLockId.increment();
        return Id.unwrap(currentLockId) - 1;
    }

    function unlock(uint256[] calldata _lockIds) external {
        IRollup rollup = IRollup(manager.rollup());
        for (uint256 i = 0; i < _lockIds.length; i++) {
            if (Id.unwrap(nextIdToUnlock) != _lockIds[i]) revert("Must unlock in sequential order");
            // State root associated with lock ID must be confirmed and cannot be fraudulent
            if (rollup.isFraudulentLockId(_lockIds[i])) {
                revert("State root associated with lock ID was marked as fraudulent");
            }
            if (!rollup.isConfirmedLockId(_lockIds[i])) {
                revert("State root associated with lock ID has not been confirmed");
            }

            LockRecord memory lockRecord = locks[_lockIds[i]];
            if (lockRecord.blockNumber + manager.fraudPeriod() > block.number) {
                revert("Lock has not passed fraud period.");
            }
            // Get active tranches at time of lock
            uint256[3] memory tranches = getActiveTranches(lockRecord.blockNumber);
            uint256 amountToUnlock = lockRecord.amountLocked;
            // loop through tranches and unlock
            for (uint256 t = 0; t < tranches.length; t++) {
                if (amountToUnlock == 0) break;
                uint256 locked = totals[lockRecord.asset][tranches[t]].locked;
                if (locked == 0) continue;
                if (amountToUnlock <= locked) {
                    totals[lockRecord.asset][tranches[t]].locked -= amountToUnlock;
                    amountToUnlock = 0;
                } else {
                    // set available in tranche to: available - _amountToLock
                    totals[lockRecord.asset][tranches[t]].locked = 0;
                    amountToUnlock -= locked;
                }
            }
            locks[_lockIds[i]].amountLocked = 0;
            nextIdToUnlock = nextIdToUnlock.increment();
        }
    }

    function reward(uint256 _lockId, uint256 _chainId, address _asset, uint256 _amount) external {
        if (msg.sender != manager.rollup()) revert();
        rewards[_lockId][_chainId][_asset] += _amount;
    }

    function slash(uint256 _lockId) external {
        IRollup rollup = IRollup(manager.rollup());
        if (!rollup.isFraudulentLockId(_lockId)) {
            revert("State root associated with lock ID was NOT marked as fraudulent");
        }
        if (Id.unwrap(nextIdToUnlock) != _lockId) {
            revert("Slashing must occur in sequential order");
        }

        // TODO: slashing logic

        nextIdToUnlock = nextIdToUnlock.increment();
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
    function claim(ClaimParams calldata _params) external payable {
        for (uint256 d = 0; d < _params.depositId.length; d++) {
            // get deposit record
            uint256 depositId = _params.depositId[d];
            DepositRecord storage depositRecord = deposits[depositId];
            // deposit record must belong to sender
            if (depositRecord.staker != msg.sender) revert("Sender not staker of deposit record");
            for (uint256 l = 0; l < _params.lockId.length; l++) {
                uint256 lockId = _params.lockId[l];
                // get lock record
                LockRecord storage lockRecord = locks[lockId];

                // Deposit should be eligible for the given lock record
                {
                    uint256[ACTIVE_PERIODS] memory eligibleTranches = getActiveTranches(lockRecord.blockNumber);
                    if (
                        depositRecord.blockNumber >= lockRecord.blockNumber
                            || depositRecord.unlockTime > eligibleTranches[ACTIVE_PERIODS - 1]
                            || lockRecord.blockNumber > depositRecord.unlockTime - manager.fraudPeriod()
                            || lockRecord.asset != depositRecord.asset
                    ) continue;
                }
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

        IPortal.Obligation[] memory obligations = new IPortal.Obligation[](_params.rewardAsset.length);
        for (uint256 i = 0; i < _params.rewardAsset.length; i++) {
            uint256 amountToClaim = toClaim[msg.sender][_params.rewardChainId][_params.rewardAsset[i]];
            if (amountToClaim == 0) revert("Amount to claim is 0");
            obligations[i] = IPortal.Obligation(msg.sender, _params.rewardAsset[i], amountToClaim);
            // Set to 0 so it can't be used again
            toClaim[msg.sender][_params.rewardChainId][_params.rewardAsset[i]] = 0;
        }
        IProcessingChainLz(IProcessingChainManager(address(manager)).relayer()).sendObligations{ value: msg.value }(
            _params.rewardChainId, obligations, bytes(""), msg.sender
        );
    }

    // Returns block numbers of periods that can be staked into
    // Block number represents time at which all deposits for that period can be withdrawn
    // Can be used to determine the total available + locked collateral that's eligible for reward
    function getActiveTranches() public view returns (uint256[ACTIVE_PERIODS] memory tranches) {
        return getActiveTranches(block.number);
    }

    function getActiveTranches(uint256 _blockNumber) public view returns (uint256[ACTIVE_PERIODS] memory tranches) {
        // Number of blocks passed for the current period
        // If 0, then the current block number is the exact beginning of a new period
        uint256 r = _blockNumber % PERIOD_LENGTH;
        // Start time of the earliest period
        uint256 current = _blockNumber - (r > 0 ? r : 0);
        // If past the deposit cutoff, then the current period is closed and the subsequent is earliest.
        if (r >= manager.fraudPeriod()) {
            current += PERIOD_LENGTH;
        }
        for (uint256 i = 0; i < ACTIVE_PERIODS; i++) {
            tranches[i] = current + (PERIOD_LENGTH * (i + 1));
        }
    }

    // Below are view functions used only for querying data off-chain

    function getUserDepositIds(address _user) external view returns (uint256[] memory) {
        return userDeposits[_user].values();
    }

    function getUserDepositRecords(address _user) external view returns (DepositRecord[] memory) {
        uint256[] memory depositIds = userDeposits[_user].values();
        DepositRecord[] memory records = new DepositRecord[](depositIds.length);
        for (uint256 i = 0; i < depositIds.length; i++) {
            records[i] = deposits[depositIds[i]];
        }
        return records;
    }

    function getAllLockRecords() external view returns (LockRecord[] memory) {
        LockRecord[] memory records = new LockRecord[](Id.unwrap(currentLockId));
        for (uint256 i = 0; i < Id.unwrap(currentLockId); i++) {
            records[i] = locks[i];
        }
        return records;
    }

    function getLockRecords(uint256 _from, uint256 _to) external view returns (LockRecord[] memory) {
        if (_from >= _to) revert("Invalid range");
        LockRecord[] memory records = new LockRecord[](_to - _from);
        for (uint256 i = _from; i < _to; i++) {
            records[i - _from] = locks[i];
        }
        return records;
    }

    function getUnlocked(address _staker)
        external
        view
        returns (uint256 stablecoinUnlocked, uint256 protocolUnlocked)
    {
        for (uint256 i = 0; i < userDeposits[_staker].length(); i++) {
            DepositRecord memory depositRecord = deposits[userDeposits[_staker].at(i)];
            TotalAmount memory total = totals[depositRecord.asset][depositRecord.unlockTime];
            uint256 unlocked = ((total.total - total.locked) * depositRecord.amount) / total.total;
            uint256 available = unlocked - depositRecord.withdrawn;
            if (depositRecord.asset == protocolToken) {
                protocolUnlocked += available;
            }
            if (depositRecord.asset == stablecoin) {
                stablecoinUnlocked += available;
            }
        }
    }

    function getAvailableToClaim(
        address _staker,
        uint256 _chainId,
        address _asset
    )
        external
        view
        returns (uint256 availableToClaim)
    {
        uint256 fraudPeriod = manager.fraudPeriod();
        for (uint256 i = 0; i < userDeposits[_staker].length(); i++) {
            DepositRecord memory depositRecord = deposits[userDeposits[_staker].at(i)];

            for (uint256 l = 0; l < Id.unwrap(currentLockId); l++) {
                LockRecord memory lockRecord = locks[l];
                // Deposit should be eligible for the given lock record
                if (
                    depositRecord.blockNumber >= lockRecord.blockNumber
                        || lockRecord.blockNumber > depositRecord.unlockTime - fraudPeriod
                        || lockRecord.asset != depositRecord.asset
                ) continue;

                // get rewards for lock record
                uint256 totalRewards = rewards[l][_chainId][_asset];
                // calculate how much goes to deposit record
                // totalReward * (deposited / totalDeposited)
                uint256 claimable = (totalRewards * depositRecord.amount * 1e5) / (lockRecord.totalAvailable * 1e5);
                // get how much has already been claimed
                uint256 claimed = claimedRewards[i][l][_chainId][_asset];
                // check if there's anything that can be claimed
                if (claimed < claimable) {
                    uint256 amountToClaim = claimable - claimed;
                    availableToClaim += amountToClaim;
                }
            }
        }
    }
}
