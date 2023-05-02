// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Test } from "forge-std/Test.sol";

import "../src/Manager/Manager.sol";
import "../src/Portal/Portal.sol";
import "@openzeppelin/token/ERC20/ERC20.sol";

contract PortalTest is Test {
    using IdLib for Id;
    
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    Manager internal manager;
    Portal internal portal;

    address internal alice;
    address internal bob;

    ERC20 internal token;

    event DepositUtxo(
        address wallet,
        uint256 amount,
        address token,
        address participatingInterface,
        Id chainSequenceId,
        bytes32 utxo
    );

    function setUp() public virtual {
        participatingInterface = vm.addr(0xEC);
        admin = vm.addr(0xAD);
        validator = vm.addr(0xDA);

        manager = new Manager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator
        });
        portal = Portal(manager.portal());

        alice = vm.addr(0xA11CE);
        bob = vm.addr(0xB0B);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        token = new ERC20("TestToken", "TST");
    }

    function test_depositNativeAsset() external {
        uint256 aliceBalanceBefore = alice.balance;
        uint256 portalBalanceBefore = address(portal).balance;
        Id chainSequenceIdBefore = portal.chainSequenceId();
        uint256 amount = 0.5 ether;

        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, amount, chainSequenceIdBefore, Id.wrap(block.chainid)
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
        assertTrue(chainSequenceIdBefore.increment() == portal.chainSequenceId());
        assertEq(portal.balances(utxo), amount);
    }

    function test_depositNativeAssetUniqueness() external {
        uint256 amount = 0.5 ether;
        Id chainSequenceIdBefore = portal.chainSequenceId();
        StateUpdateLibrary.Deposit memory deposit =
            StateUpdateLibrary.Deposit(alice, address(0), participatingInterface, amount, chainSequenceIdBefore, Id.wrap(block.chainid));
        vm.prank(alice);
        portal.depositNativeAsset{value: amount}();

        // Second deposit should have different UTXO hash and chain sequence ID
        deposit = StateUpdateLibrary.Deposit(alice, address(0), participatingInterface, amount, chainSequenceIdBefore.increment(), Id.wrap(block.chainid));
        bytes32 utxo = keccak256(abi.encode(deposit));
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit DepositUtxo(alice, amount, address(0), participatingInterface, chainSequenceIdBefore.increment(), utxo);
        portal.depositNativeAsset{value: amount}();
    }

    function test_depositToken() external {
        uint256 amount = 0.5 ether;
        deal({token: address(token), to: alice, give: amount});
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 portalBalanceBefore = token.balanceOf(address(portal));
        Id chainSequenceIdBefore = portal.chainSequenceId();

        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(token), participatingInterface, amount, chainSequenceIdBefore, Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));

        vm.startPrank(alice);
        token.approve({spender: address(portal), amount: amount});
        vm.expectEmit(true, true, true, true);
        emit DepositUtxo(alice, amount, address(token), participatingInterface, chainSequenceIdBefore, utxo);
        portal.depositToken({_token: address(token), _amount: amount});
        vm.stopPrank();

        uint256 aliceBalanceAfter = token.balanceOf(alice);
        uint256 portalBalanceAfter = token.balanceOf(address(portal));
        assertEq(aliceBalanceBefore - aliceBalanceAfter, amount);
        assertEq(portalBalanceAfter - portalBalanceBefore, amount);
        assertTrue(chainSequenceIdBefore.increment() == portal.chainSequenceId());
        assertEq(portal.balances(utxo), amount);
    }
}
