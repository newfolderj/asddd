// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./util/BaseTest.sol";

contract RollupTest is BaseTest {
    // using IdLib for Id;

    function setUp() public override {
        super.setUp();
    }

    function test_processSettlement() external {
        // Alice makes the first deposit
        uint256 amount = 0.5 ether;
        vm.prank(alice);
        portal.depositNativeAsset{ value: amount }();

        // Create corresponding Deposit and UTXO objects
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, amount, ID_ZERO, Id.wrap(block.chainid)
        );

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

        // Simulate passage of time
        vm.roll(block.number + rollup.CONFIRMATION_BLOCKS());

        // Confirm state root
        rollup.confirmStateRoot();

        // Report settlement as the validator
        vm.prank(validator);
        rollup.processSettlement({
            _stateRootId: ID_ONE,
            _signedUpdate: stateUpdate,
            _proof: proof
        });

        // Alice can now withdraw original deposit
        vm.prank(alice);
        portal.withdraw({ _amount: amount, _token: address(0) });
    }

    function test_submitsSettlement() external {
        // Alice makes the first deposit
        uint256 amount = 0.5 ether;
        vm.prank(alice);
        portal.depositNativeAsset{ value: amount }();

        // Create corresponding Deposit and UTXO objects
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, amount, ID_ZERO, Id.wrap(block.chainid)
        );

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
        rollup.submitSettlement({
            _stateRoot: stateRoot,
            _signedUpdate: stateUpdate,
            _proof: proof
        });

        // Alice can now withdraw original deposit
        vm.prank(alice);
        portal.withdraw({ _amount: amount, _token: address(0) });
    }
}
