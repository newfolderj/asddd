// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./util/BaseTest.sol";

contract PortalTest is BaseTest {
    using IdLib for Id;

    function setUp() public override {
        super.setUp();
    }

    function test_depositNativeAsset() external {
        uint256 aliceBalanceBefore = alice.balance;
        uint256 portalBalanceBefore = address(portal).balance;
        Id chainSequenceIdBefore = portal.chainSequenceId();
        uint64 amount = 0.5 ether;

        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, portal.convertPrecision(amount, address(0)), chainSequenceIdBefore, Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit DepositUtxo(alice, uint256(amount), address(0), participatingInterface, chainSequenceIdBefore, utxo);
        portal.depositNativeAsset{ value: amount }();

        uint256 aliceBalanceAfter = alice.balance;
        uint256 portalBalanceAfter = address(portal).balance;
        assertEq(aliceBalanceBefore - aliceBalanceAfter, amount);
        assertEq(portalBalanceAfter - portalBalanceBefore, amount);
        assertTrue(chainSequenceIdBefore.increment() == portal.chainSequenceId());
    }

    function test_depositNativeAssetUniqueness() external {
        uint64 amount = 0.5 ether;
        Id chainSequenceIdBefore = portal.chainSequenceId();
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, amount, chainSequenceIdBefore, Id.wrap(block.chainid)
        );
        vm.prank(alice);
        portal.depositNativeAsset{ value: amount }();

        // Second deposit should have different UTXO hash and chain sequence ID
        deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, portal.convertPrecision(amount, address(0)), chainSequenceIdBefore.increment(), Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit DepositUtxo(alice, uint256(amount), address(0), participatingInterface, chainSequenceIdBefore.increment(), utxo);
        portal.depositNativeAsset{ value: amount }();
    }

    function test_depositToken() external {
        uint64 amount = 0.5 ether;
        deal({ token: address(token), to: alice, give: amount });
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 portalBalanceBefore = token.balanceOf(address(portal));
        Id chainSequenceIdBefore = portal.chainSequenceId();

        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(token), participatingInterface, portal.convertPrecision(amount, address(token)), chainSequenceIdBefore, Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));

        vm.startPrank(alice);
        token.approve({ spender: address(portal), amount: amount });
        vm.expectEmit(true, true, true, true);
        emit DepositUtxo(alice, uint256(amount), address(token), participatingInterface, chainSequenceIdBefore, utxo);
        portal.depositToken({ _token: address(token), _amount: amount });
        vm.stopPrank();

        uint256 aliceBalanceAfter = token.balanceOf(alice);
        uint256 portalBalanceAfter = token.balanceOf(address(portal));
        assertEq(aliceBalanceBefore - aliceBalanceAfter, amount);
        assertEq(portalBalanceAfter - portalBalanceBefore, amount);
        assertTrue(chainSequenceIdBefore.increment() == portal.chainSequenceId());
    }
}
