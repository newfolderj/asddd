// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Test } from "forge-std/Test.sol";

import "../src/Manager/Manager.sol";
import "../src/Portal/Portal.sol";

contract PortalTest is Test {
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    Manager internal manager;
    Portal internal portal;

    address internal alice;
    address internal bob;

    event DepositUtxo(
        address wallet,
        uint256 amount,
        address token,
        address participatingInterface,
        uint256 chainSequenceId,
        bytes32 utxo
    );

    function setUp() public virtual {
        participatingInterface = vm.addr(0xEC);
        admin = vm.addr(0xAD);
        validator = vm.addr(0xDA);

        manager = new Manager(participatingInterface, admin, validator);
        portal = Portal(manager.portal());

        alice = vm.addr(0xA11CE);
        bob = vm.addr(0xB0B);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_depositNativeAsset() external {
        uint256 aliceBalanceBefore = alice.balance;
        uint256 portalBalanceBefore = address(portal).balance;
        uint256 chainSequenceIdBefore = portal.chainSequenceId();
        uint256 amount = 0.5 ether;

        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice,
            address(0),
            participatingInterface,
            amount,
            chainSequenceIdBefore,
            block.chainid
        );
        bytes32 utxo = keccak256(abi.encode(deposit));

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit DepositUtxo(alice, amount, address(0), participatingInterface, chainSequenceIdBefore, utxo);
        portal.depositNativeAsset{value: amount}();

        uint256 aliceBalanceAfter = alice.balance;
        uint256 portalBalanceAfter = address(portal).balance;
        assertEq(aliceBalanceBefore - aliceBalanceAfter, amount);
        assertEq(portalBalanceAfter - portalBalanceBefore, amount);
        assertEq(chainSequenceIdBefore + 1, portal.chainSequenceId());
        assertEq(portal.balances(utxo), amount);
    }

    function test_depositNativeAssetUniqueness() external {
        uint256 amount = 0.5 ether;
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice,
            address(0),
            participatingInterface,
            amount,
            0,
            block.chainid
        );
        vm.prank(alice);
        portal.depositNativeAsset{value: amount}();

        // Second deposit should have different UTXO hash and chain sequence ID
        deposit = StateUpdateLibrary.Deposit(
            alice,
            address(0),
            participatingInterface,
            amount,
            1,
            block.chainid
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit DepositUtxo(alice, amount, address(0), participatingInterface, 1, utxo);
        portal.depositNativeAsset{value: amount}();
    }
}
