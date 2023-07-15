// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./util/BaseTest.sol";

contract FraudEngineTest is BaseTest {
    using IdLib for Id;

    uint256 internal wrongKey = 0xEF;

    function invalidSignStateUpdate(StateUpdateLibrary.StateUpdate memory _stateUpdate)
        internal
        view
        returns (StateUpdateLibrary.SignedStateUpdate memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongKey, sigUtil.typeHashStateUpdate(_stateUpdate));
        return StateUpdateLibrary.SignedStateUpdate(_stateUpdate, v, r, s);
    }

    function setUp() public override {
        super.setUp();
    }

    function signOrder(
        StateUpdateLibrary.Order memory _order,
        uint256 privKey
    )
        internal
        returns (StateUpdateLibrary.SignedOrder memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, sigUtil.typeHashOrder(_order));
        return StateUpdateLibrary.SignedOrder(_order, v, r, s);
    }

    function test_reportSignatureFraud() external {
        StateUpdateLibrary.UTXO[] memory inputs = new StateUpdateLibrary.UTXO[](1);
        bytes32[] memory hashedInputs = new bytes32[](1);
        uint256 amount = 0.5 ether;
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, amount, ID_ZERO, Id.wrap(block.chainid)
        );
        inputs[0] = depositToUtxo(deposit, 0);
        hashedInputs[0] = keccak256(abi.encode(inputs[0]));

        // Create settlement request object
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(deposit.trader, deposit.asset, Id.wrap(3), Id.wrap(2), 3, amount);
        StateUpdateLibrary.SignedStateUpdate memory stateUpdate = signStateUpdate(settlementAck);
        StateUpdateLibrary.SignedStateUpdate memory invalidUpdate =
            invalidSignStateUpdate(depositStateUpdate(bob, address(0), 1.5 ether, Id.wrap(2), 2));

        bytes32[] memory proof;
        bytes32 stateRoot;

        // Construct merkle tree of signed state updates
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(deposit, 0)))));
        data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(bob, address(0), 1 ether, ID_ONE, 1)))));
        data[2] = keccak256(abi.encode(invalidUpdate));
        data[3] = keccak256(abi.encode(stateUpdate));

        stateRoot = merkleLib.getRoot(data);

        // Propose state root as validator
        vm.prank(validator);
        rollup.proposeStateRoot(stateRoot);

        // Correct signature shouldn't be accepted as proof
        proof = merkleLib.getProof(data, 3);
        vm.expectRevert();
        fraudEngine.proveSignatureFraud({ _epoch: ID_ONE, _invalidUpdate: stateUpdate, _proof: proof });

        // Get proof of the signed state update with incorrect signature
        proof = merkleLib.getProof(data, 2);

        // Report fraudulent signature
        fraudEngine.proveSignatureFraud({ _epoch: ID_ONE, _invalidUpdate: invalidUpdate, _proof: proof });

        // State root should be flagged as fraudulent
        assert(rollup.fraudulent(ID_ONE, stateRoot));

        // Simulate passage of time
        vm.roll(block.number + rollup.CONFIRMATION_BLOCKS());

        // Confirming state root should fail
        vm.expectRevert();
        rollup.confirmStateRoot();

        // Process settlement should fail
        vm.prank(validator);
        vm.expectRevert();
        Rollup.SettlementParams[] memory params = new Rollup.SettlementParams[](1);
        params[0] = Rollup.SettlementParams(stateUpdate, ID_ONE, proof);
        rollup.processSettlements(Id.wrap(block.chainid), params);

        // Alice withdraw should fail
        vm.prank(alice);
        vm.expectRevert();
        portal.withdraw({ _amount: amount, _token: address(0) });
    }
}
