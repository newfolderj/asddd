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
        depositId[0] = 0;
        depositId[1] = 1;
        address[] memory rewardAsset = new address[](1);
        rewardAsset[0] = address(0);
        Staking.ClaimParams memory claimParams = Staking.ClaimParams(lockId, depositId, chainId, rewardAsset);
        vm.startPrank(validator);
        staking.claim{ value: 1 ether }(claimParams);
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
        rollup.confirmStateRoot();

        // Simulate passage of time to unlock time of deposit
        (,,,,uint256 unlockTime,) = staking.deposits(depositId[0]);
        vm.roll(unlockTime);
        // Staker should not be able to withdraw collateral since it wasn't unlocked
        vm.prank(validator);
        vm.expectRevert();
        staking.withdraw(depositId);

        // Unlock collateral
        staking.unlock(lockId);

        vm.prank(validator);
        staking.withdraw(depositId);

    }

    function test_submitsSettlement() external {
        vm.chainId(chainId);
        rollup = Rollup(manager.rollup());
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

        // Submit settlement as the validator
        vm.prank(validator);
        rollup.submitSettlement{ value: 1 ether }({ _stateRoot: stateRoot, _signedUpdate: stateUpdate, _proof: proof });

        // Alice can now withdraw original deposit minus settlement fee
        (uint256 insuranceFee, uint256 stakerRewards) = IFeeManager(address(manager)).calculateSettlementFees(amount);
        vm.prank(alice);
        portal.withdraw({ _amount: amount - (insuranceFee + stakerRewards), _token: address(0) });
    }
}
