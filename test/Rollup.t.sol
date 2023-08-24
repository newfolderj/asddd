// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./util/BaseTest.sol";
import "forge-std/console.sol";

contract RollupTest is BaseTest {
    // using IdLib for Id;

    function setUp() public override {
        super.setUp();
    }

    function test_processSettlement() external {
        // Forge seems to run this entire test (including staking deposits in super) in a single block
        // so we need to move the block number forward by at least 1.
        vm.roll(block.number + 1);
        // Alice makes the first deposit
        uint256 amount = 0.5 ether;
        vm.prank(alice);
        portal.depositNativeAsset{ value: amount }();

        // Create corresponding Deposit and UTXO objects
        StateUpdateLibrary.Deposit memory deposit =
            StateUpdateLibrary.Deposit(alice, address(0), participatingInterface, amount, ID_ZERO, Id.wrap(chainId));

        // Bob makes some deposits
        vm.startPrank(bob);
        portal.depositNativeAsset{ value: 1 ether }();
        portal.depositNativeAsset{ value: 1.5 ether }();
        vm.stopPrank();

        // Alice requests settlement
        vm.prank(alice);
        portal.requestSettlement(address(0));

        // Create settlement request object
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(deposit.trader, deposit.asset, Id.wrap(3), Id.wrap(2), 3, amount);
        StateUpdateLibrary.SignedStateUpdate memory stateUpdate = signStateUpdate(settlementAck);

        bytes32[] memory proof;
        bytes32 stateRoot;

        // Construct merkle tree of signed state updates
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(deposit, 0)))));
        data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(bob, address(0), 1 ether, ID_ONE, 1)))));
        data[2] =
            keccak256(abi.encode((signStateUpdate(depositStateUpdate(bob, address(0), 1.5 ether, Id.wrap(2), 2)))));
        data[3] = keccak256(abi.encode(stateUpdate));

        // Get state root and proof of the signed state update with settlement message
        proof = m.getProof(data, 3);
        stateRoot = m.getRoot(data);

        // Propose state root as validator
        vm.prank(validator);
        rollup.proposeStateRoot(stateRoot);

        // Report settlement as the validator
        vm.prank(validator);
        Rollup.SettlementParams[] memory params = new Rollup.SettlementParams[](1);
        params[0] = Rollup.SettlementParams(stateUpdate, ID_ONE, proof);
        rollup.processSettlements{ value: 1 ether }(Id.wrap(chainId), params);

        // Alice can now withdraw original deposit minus settlement fee
        (uint256 insuranceFee, uint256 stakerRewards) = IFeeManager(address(manager)).calculateSettlementFees(amount);
        vm.prank(alice);
        portal.withdraw({ _amount: amount - (insuranceFee + stakerRewards), _token: address(0) });

        // Staker should be able to claim rewards
        uint256[] memory lockId = new uint256[](2);
        lockId[0] = 1;
        lockId[1] = 2;
        uint256[] memory depositId = new uint256[](2);
        depositId[0] = 1;
        depositId[1] = 2;
        address[] memory rewardAsset = new address[](1);
        rewardAsset[0] = address(0);
        Staking.ClaimParams memory claimParams = Staking.ClaimParams(lockId, depositId, chainId, rewardAsset);

        uint256 claimAmount = staking.getAvailableToClaim(validator, chainId, address(0));
        if (claimAmount == 0) revert("Claim amount should not be 0");
        vm.startPrank(validator);
        staking.claim{ value: 1 ether }(claimParams);
        if (staking.getAvailableToClaim(validator, chainId, address(0)) != 0) {
            revert("Claim amount should be 0 after claiming");
        }
        portal.withdraw(stakerRewards, rewardAsset[0]);

        // Staker should not be able to withdraw staked assets
        vm.expectRevert();
        staking.withdraw(depositId);
        vm.stopPrank();

        // Simulate passage of time
        vm.roll(block.number + manager.fraudPeriod());

        // should not be able to unlock stake until state root is confirmed
        vm.expectRevert();
        staking.unlock(lockId);

        // Confirm state root
        vm.prank(validator);
        rollup.confirmStateRoot();

        // unlocked deposits view function should be all 0s
        Staking.AvailableDeposit[] memory unlockedIds = staking.getAvailableDeposits(validator);
        for (uint256 i = 0; i < unlockedIds.length; i++) {
            if (unlockedIds[i].id != 0) revert();
        }
        // getUnlockedAmount view function should return 0
        (uint256 unlockedStablecoin, uint256 unlockedProtocol) = staking.getUnlocked(validator);
        if (unlockedStablecoin != 0) revert();
        if (unlockedProtocol != 0) revert();

        // Simulate passage of time to unlock time of deposit
        (,,,, uint256 unlockTime,) = staking.deposits(depositId[0]);
        vm.roll(unlockTime);
        // Staker should not be able to withdraw collateral since it wasn't unlocked
        vm.prank(validator);
        // vm.expectRevert();
        staking.withdraw(depositId);

        // Unlock collateral
        staking.unlock(lockId);

        // none of the unlocked deposit IDs should be 0
        unlockedIds = staking.getAvailableDeposits(validator);
        for (uint256 i = 0; i < unlockedIds.length; i++) {
            if (unlockedIds[i].id == 0) revert();
        }
        // getUnlockedAmount view function should NOT return 0
        (unlockedStablecoin, unlockedProtocol) = staking.getUnlocked(validator);
        if (unlockedStablecoin == 0) revert();
        if (unlockedProtocol == 0) revert();

        // after withdrawing remaining funds, unlocked deposit IDs should show 0
        vm.prank(validator);
        staking.withdraw(depositId);

        unlockedIds = staking.getAvailableDeposits(validator);
        for (uint256 i = 0; i < unlockedIds.length; i++) {
            if (unlockedIds[i].id != 0) revert();
        }
        // getUnlockedAmount should be 0 again
        (unlockedStablecoin, unlockedProtocol) = staking.getUnlocked(validator);
        if (unlockedStablecoin != 0) revert();
        if (unlockedProtocol != 0) revert();
    }

    function test_submitSettlement() external {
        // Forge seems to run this entire test (including staking deposits in super) in a single block
        // so we need to move the block number forward by at least 1.
        vm.roll(block.number + 1);
        // Alice makes the first deposit
        uint256 amount = 0.5 ether;
        vm.prank(alice);
        portal.depositNativeAsset{ value: amount }();

        // Create corresponding Deposit and UTXO objects
        StateUpdateLibrary.Deposit memory deposit =
            StateUpdateLibrary.Deposit(alice, address(0), participatingInterface, amount, ID_ZERO, Id.wrap(chainId));

        // Bob makes some deposits
        vm.startPrank(bob);
        portal.depositNativeAsset{ value: 1 ether }();
        portal.depositNativeAsset{ value: 1.5 ether }();
        vm.stopPrank();

        // Alice requests settlement
        vm.prank(alice);
        portal.requestSettlement(address(0));

        // Create settlement request object
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(deposit.trader, deposit.asset, Id.wrap(3), Id.wrap(2), 3, amount);
        StateUpdateLibrary.SignedStateUpdate memory stateUpdate = signStateUpdate(settlementAck);

        bytes32[] memory proof;
        bytes32 stateRoot;

        // Construct merkle tree of signed state updates
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(deposit, 0)))));
        data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(bob, address(0), 1 ether, ID_ONE, 1)))));
        data[2] =
            keccak256(abi.encode((signStateUpdate(depositStateUpdate(bob, address(0), 1.5 ether, Id.wrap(2), 2)))));
        data[3] = keccak256(abi.encode(stateUpdate));

        // Get state root and proof of the signed state update with settlement message
        proof = m.getProof(data, 3);
        stateRoot = m.getRoot(data);

        // Propose state root as validator
        vm.prank(validator);
        rollup.submitSettlement{ value: 0.5 ether }(stateRoot, stateUpdate, proof);

        // Alice can now withdraw original deposit minus settlement fee
        (uint256 insuranceFee, uint256 stakerRewards) = IFeeManager(address(manager)).calculateSettlementFees(amount);
        vm.prank(alice);
        portal.withdraw({ _amount: amount - (insuranceFee + stakerRewards), _token: address(0) });

        // Staker should be able to claim rewards
        uint256[] memory lockId = new uint256[](2);
        lockId[0] = 0;
        lockId[1] = 1;
        uint256[] memory depositId = new uint256[](2);
        depositId[0] = 1;
        depositId[1] = 2;
        address[] memory rewardAsset = new address[](1);
        rewardAsset[0] = address(0);
        Staking.ClaimParams memory claimParams = Staking.ClaimParams(lockId, depositId, chainId, rewardAsset);

        uint256 claimAmount = staking.getAvailableToClaim(validator, chainId, address(0));
        if (claimAmount == 0) revert("Claim amount should not be 0");
        vm.startPrank(validator);
        staking.claim{ value: 1 ether }(claimParams);
        if (staking.getAvailableToClaim(validator, chainId, address(0)) != 0) {
            revert("Claim amount should be 0 after claiming");
        }
        portal.withdraw(stakerRewards, rewardAsset[0]);

        // Staker should not be able to withdraw staked assets
        vm.expectRevert();
        staking.withdraw(depositId);
        vm.stopPrank();

        // Simulate passage of time
        vm.roll(block.number + manager.fraudPeriod());

        // should not be able to unlock stake until state root is confirmed
        vm.expectRevert();
        staking.unlock(lockId);

        // Confirm state root
        vm.prank(validator);
        rollup.confirmStateRoot();

        // unlocked deposits view function should be all 0s
        Staking.AvailableDeposit[] memory unlockedIds = staking.getAvailableDeposits(validator);
        for (uint256 i = 0; i < unlockedIds.length; i++) {
            if (unlockedIds[i].id != 0) revert();
        }
        // getUnlockedAmount view function should return 0
        (uint256 unlockedStablecoin, uint256 unlockedProtocol) = staking.getUnlocked(validator);
        if (unlockedStablecoin != 0) revert();
        if (unlockedProtocol != 0) revert();

        // Simulate passage of time to unlock time of deposit
        (,,,, uint256 unlockTime,) = staking.deposits(depositId[0]);
        vm.roll(unlockTime);
        // Staker should not be able to withdraw collateral since it wasn't unlocked
        vm.prank(validator);
        // vm.expectRevert();
        staking.withdraw(depositId);

        // Unlock collateral
        staking.unlock(lockId);

        // none of the unlocked deposit IDs should be 0
        unlockedIds = staking.getAvailableDeposits(validator);
        for (uint256 i = 0; i < unlockedIds.length; i++) {
            if (unlockedIds[i].id == 0) revert();
        }
        // getUnlockedAmount view function should NOT return 0
        (unlockedStablecoin, unlockedProtocol) = staking.getUnlocked(validator);
        if (unlockedStablecoin == 0) revert();
        if (unlockedProtocol == 0) revert();

        // after withdrawing remaining funds, unlocked deposit IDs should show 0
        vm.prank(validator);
        staking.withdraw(depositId);

        unlockedIds = staking.getAvailableDeposits(validator);
        for (uint256 i = 0; i < unlockedIds.length; i++) {
            if (unlockedIds[i].id != 0) revert();
        }
        // getUnlockedAmount should be 0 again
        (unlockedStablecoin, unlockedProtocol) = staking.getUnlocked(validator);
        if (unlockedStablecoin != 0) revert();
        if (unlockedProtocol != 0) revert();
    }

    function test_submitSettlementCollateralFallback() external {
        // Move time forward so all collateral is expired
        vm.roll(block.number + 1_000_000);
        // Alice makes the first deposit
        uint256 amount = 0.5 ether;
        vm.prank(alice);
        portal.depositNativeAsset{ value: amount }();

        // Create corresponding Deposit and UTXO objects
        StateUpdateLibrary.Deposit memory deposit =
            StateUpdateLibrary.Deposit(alice, address(0), participatingInterface, amount, ID_ZERO, Id.wrap(chainId));

        // Bob makes some deposits
        vm.startPrank(bob);
        portal.depositNativeAsset{ value: 1 ether }();
        portal.depositNativeAsset{ value: 1.5 ether }();
        vm.stopPrank();

        // Alice requests settlement
        vm.prank(alice);
        portal.requestSettlement(address(0));

        // Create settlement request object
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(deposit.trader, deposit.asset, Id.wrap(3), Id.wrap(2), 3, amount);
        StateUpdateLibrary.SignedStateUpdate memory stateUpdate = signStateUpdate(settlementAck);

        bytes32[] memory proof;
        bytes32 stateRoot;

        // Construct merkle tree of signed state updates
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(deposit, 0)))));
        data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(bob, address(0), 1 ether, ID_ONE, 1)))));
        data[2] =
            keccak256(abi.encode((signStateUpdate(depositStateUpdate(bob, address(0), 1.5 ether, Id.wrap(2), 2)))));
        data[3] = keccak256(abi.encode(stateUpdate));

        // Get state root and proof of the signed state update with settlement message
        proof = m.getProof(data, 3);
        stateRoot = m.getRoot(data);

        // Propose state root as validator
        vm.prank(validator);
        rollup.submitSettlement{ value: 0.5 ether }(stateRoot, stateUpdate, proof);

        // Alice can now withdraw original deposit minus settlement fee
        (uint256 insuranceFee, uint256 stakerRewards) = IFeeManager(address(manager)).calculateSettlementFees(amount);
        vm.prank(alice);
        portal.withdraw({ _amount: amount - (insuranceFee + stakerRewards), _token: address(0) });
    }
}
