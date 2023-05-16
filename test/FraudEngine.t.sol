// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./util/BaseTest.sol";

contract FraudEngineTest is BaseTest {
    using IdLib for Id;

    uint256 internal wrongKey = 0xEF;
    FraudEngine internal fraudEngine;

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
        fraudEngine = FraudEngine(address(rollup));
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
            settlementStateUpdate(deposit.trader, deposit.asset, Id.wrap(3), Id.wrap(2), 3, hashedInputs);
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
        assert(rollup.fraudulent(stateRoot));

        // Simulate passage of time
        vm.roll(block.number + rollup.CONFIRMATION_BLOCKS());

        // Confirming state root should fail
        vm.expectRevert();
        rollup.confirmStateRoot();

        // Process settlement should fail
        vm.prank(validator);
        vm.expectRevert();
        rollup.processSettlement({ _stateRootId: ID_ONE, _signedUpdate: stateUpdate, _proof: proof, _inputs: inputs });

        // Alice withdraw should fail
        vm.prank(alice);
        vm.expectRevert();
        portal.withdraw({ _amount: amount, _token: address(0) });
    }

    function test_reportInvalidOutput() external {
        // Merkle Tree that will hold signed state updates
        bytes32[] memory data = new bytes32[](4);

        StateUpdateLibrary.UTXO[] memory inputsA = new StateUpdateLibrary.UTXO[](1);
        StateUpdateLibrary.UTXO[] memory inputsB = new StateUpdateLibrary.UTXO[](1);

        StateUpdateLibrary.UTXO[] memory outputsA = new StateUpdateLibrary.UTXO[](1);

        {
            StateUpdateLibrary.Deposit memory depositA = StateUpdateLibrary.Deposit(
                alice, address(0), participatingInterface, 1 ether, ID_ZERO, Id.wrap(block.chainid)
            );
            StateUpdateLibrary.Deposit memory depositB = StateUpdateLibrary.Deposit(
                bob, address(token), participatingInterface, 1 ether, ID_ONE, Id.wrap(block.chainid)
            );

            inputsA[0] = depositToUtxo(depositA, 0);
            inputsB[0] = depositToUtxo(depositB, 1);
            data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositA, 0)))));
            data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositB, 1)))));
        }

        outputsA[0] = utxoToTradeUtxo({ _input: inputsA[0], _stateUpdateIdTrade: 2, _recipient: bob });
        // Set the parent to a hash that's not in the inputs
        outputsA[0].parentUtxo = keccak256("test");

        StateUpdateLibrary.SignedStateUpdate memory stateUpdate;

        {
            bytes32[] memory hashedInputsA = new bytes32[](1);
            bytes32[] memory hashedInputsB = new bytes32[](1);
            hashedInputsA[0] = keccak256(abi.encode(inputsA[0]));
            hashedInputsB[0] = keccak256(abi.encode(inputsB[0]));
            StateUpdateLibrary.UTXO[] memory outputsB = new StateUpdateLibrary.UTXO[](1);

            bytes32[] memory hashedOutputsA = new bytes32[](1);
            hashedOutputsA[0] = keccak256(abi.encode(outputsA[0]));
            bytes32[] memory hashedOutputsB = new bytes32[](1);
            hashedOutputsB[0] = keccak256(abi.encode(outputsB[0]));
            outputsB[0] = utxoToTradeUtxo({ _input: inputsB[0], _stateUpdateIdTrade: 2, _recipient: alice });

            // Create trade object
            uint256 size = 1 ether;
            uint256 price = 1;
            StateUpdateLibrary.Product memory product =
                StateUpdateLibrary.Product(address(0), block.chainid, address(token), block.chainid);
            StateUpdateLibrary.Trade memory trade = StateUpdateLibrary.Trade(
                StateUpdateLibrary.TradeParams(
                    participatingInterface,
                    signOrder(StateUpdateLibrary.Order(product, true, size, price), aliceKey),
                    signOrder(StateUpdateLibrary.Order(product, false, size, price), bobKey),
                    product,
                    size,
                    price
                ),
                hashedInputsA,
                hashedInputsB,
                hashedOutputsA,
                hashedOutputsB
            );
            StateUpdateLibrary.StateUpdate memory tradeStateUpdate = tradeToStateUpdate(trade, 2);
            stateUpdate = signStateUpdate(tradeStateUpdate);
        }

        data[2] = keccak256(abi.encode(stateUpdate));

        // Propose state root as validator
        vm.startPrank(validator);
        rollup.proposeStateRoot(merkleLib.getRoot(data));
        vm.stopPrank();

        fraudEngine.proveInvalidOutput({
            _epoch: ID_ONE,
            _invalidUpdate: stateUpdate,
            _inputs: inputsA,
            _outputIndex: 0,
            _output: outputsA[0],
            _side: true,
            _proof: merkleLib.getProof(data, 2)
        });

        // State root should be flagged as fraudulent
        assert(rollup.fraudulent(merkleLib.getRoot(data)));
    }

    function test_reportAssetMismatchTrade() external {
        bytes32[] memory data = new bytes32[](4);

        StateUpdateLibrary.UTXO[] memory inputsA = new StateUpdateLibrary.UTXO[](1);
        StateUpdateLibrary.UTXO[] memory inputsB = new StateUpdateLibrary.UTXO[](1);

        StateUpdateLibrary.UTXO[] memory outputsA = new StateUpdateLibrary.UTXO[](1);

        {
            StateUpdateLibrary.Deposit memory depositA = StateUpdateLibrary.Deposit(
                alice, address(0), participatingInterface, 1 ether, ID_ZERO, Id.wrap(block.chainid)
            );
            StateUpdateLibrary.Deposit memory depositB = StateUpdateLibrary.Deposit(
                bob, address(token), participatingInterface, 1 ether, ID_ONE, Id.wrap(block.chainid)
            );

            inputsA[0] = depositToUtxo(depositA, 0);
            inputsB[0] = depositToUtxo(depositB, 1);
            data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositA, 0)))));
            data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositB, 1)))));
        }

        outputsA[0] = utxoToTradeUtxo({ _input: inputsA[0], _stateUpdateIdTrade: 2, _recipient: bob });
        // Set output to have wrong asset address
        outputsA[0].asset = address(token);

        StateUpdateLibrary.SignedStateUpdate memory stateUpdate;

        {
            bytes32[] memory hashedInputsA = new bytes32[](1);
            bytes32[] memory hashedInputsB = new bytes32[](1);
            hashedInputsA[0] = keccak256(abi.encode(inputsA[0]));
            hashedInputsB[0] = keccak256(abi.encode(inputsB[0]));
            StateUpdateLibrary.UTXO[] memory outputsB = new StateUpdateLibrary.UTXO[](1);

            bytes32[] memory hashedOutputsA = new bytes32[](1);
            hashedOutputsA[0] = keccak256(abi.encode(outputsA[0]));
            bytes32[] memory hashedOutputsB = new bytes32[](1);
            hashedOutputsB[0] = keccak256(abi.encode(outputsB[0]));
            outputsB[0] = utxoToTradeUtxo({ _input: inputsB[0], _stateUpdateIdTrade: 2, _recipient: alice });

            // Create trade object
            uint256 size = 1 ether;
            uint256 price = 1;
            StateUpdateLibrary.Product memory product =
                StateUpdateLibrary.Product(address(0), block.chainid, address(token), block.chainid);
            StateUpdateLibrary.Trade memory trade = StateUpdateLibrary.Trade(
                StateUpdateLibrary.TradeParams(
                    participatingInterface,
                    signOrder(StateUpdateLibrary.Order(product, true, size, price), aliceKey),
                    signOrder(StateUpdateLibrary.Order(product, false, size, price), bobKey),
                    product,
                    size,
                    price
                ),
                hashedInputsA,
                hashedInputsB,
                hashedOutputsA,
                hashedOutputsB
            );
            StateUpdateLibrary.StateUpdate memory tradeStateUpdate = tradeToStateUpdate(trade, 2);
            stateUpdate = signStateUpdate(tradeStateUpdate);
        }

        data[2] = keccak256(abi.encode(stateUpdate));

        // Propose state root as validator
        vm.startPrank(validator);
        rollup.proposeStateRoot(merkleLib.getRoot(data));
        vm.stopPrank();

        fraudEngine.proveAssetMismatchTrade({
            _epoch: ID_ONE,
            _invalidUpdate: stateUpdate,
            _index: 0,
            _mismatched: outputsA[0],
            _inputsOrOutputs: false,
            _side: true,
            _proof: merkleLib.getProof(data, 2)
        });

        // State root should be flagged as fraudulent
        assert(rollup.fraudulent(merkleLib.getRoot(data)));
    }

    function test_reportDoubleSpendInput() external {
        // Merkle Tree that will hold signed state updates
        bytes32[] memory data = new bytes32[](4);

        StateUpdateLibrary.UTXO[] memory inputsA = new StateUpdateLibrary.UTXO[](1);
        StateUpdateLibrary.UTXO[] memory inputsB = new StateUpdateLibrary.UTXO[](1);
        bytes32[] memory hashedInputsA = new bytes32[](1);

        StateUpdateLibrary.UTXO[] memory outputsA = new StateUpdateLibrary.UTXO[](1);
        StateUpdateLibrary.Deposit memory depositA = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, 1 ether, ID_ZERO, Id.wrap(block.chainid)
        );
        {
            StateUpdateLibrary.Deposit memory depositB = StateUpdateLibrary.Deposit(
                bob, address(token), participatingInterface, 1 ether, ID_ONE, Id.wrap(block.chainid)
            );

            inputsA[0] = depositToUtxo(depositA, 0);
            inputsB[0] = depositToUtxo(depositB, 1);
            data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositA, 0)))));
            data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositB, 1)))));
        }

        StateUpdateLibrary.SignedStateUpdate memory tradeStateUpdate;

        {
            bytes32[] memory hashedInputsB = new bytes32[](1);
            hashedInputsA[0] = keccak256(abi.encode(inputsA[0]));
            hashedInputsB[0] = keccak256(abi.encode(inputsB[0]));
            StateUpdateLibrary.UTXO[] memory outputsB = new StateUpdateLibrary.UTXO[](1);

            bytes32[] memory hashedOutputsA = new bytes32[](1);
            hashedOutputsA[0] = keccak256(abi.encode(outputsA[0]));
            bytes32[] memory hashedOutputsB = new bytes32[](1);
            hashedOutputsB[0] = keccak256(abi.encode(outputsB[0]));
            outputsB[0] = utxoToTradeUtxo({ _input: inputsB[0], _stateUpdateIdTrade: 2, _recipient: alice });

            // Create trade object
            uint256 size = 1 ether;
            uint256 price = 1;
            StateUpdateLibrary.Product memory product =
                StateUpdateLibrary.Product(address(0), block.chainid, address(token), block.chainid);
            StateUpdateLibrary.Trade memory trade = StateUpdateLibrary.Trade(
                StateUpdateLibrary.TradeParams(
                    participatingInterface,
                    signOrder(StateUpdateLibrary.Order(product, true, size, price), aliceKey),
                    signOrder(StateUpdateLibrary.Order(product, false, size, price), bobKey),
                    product,
                    size,
                    price
                ),
                hashedInputsA,
                hashedInputsB,
                hashedOutputsA,
                hashedOutputsB
            );
            StateUpdateLibrary.StateUpdate memory t = tradeToStateUpdate(trade, 2);
            tradeStateUpdate = signStateUpdate(t);
        }

        data[2] = keccak256(abi.encode(tradeStateUpdate));

        // Re-use deposit as input to a settlement request
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(depositA.trader, depositA.asset, Id.wrap(3), Id.wrap(2), 3, hashedInputsA);
        StateUpdateLibrary.SignedStateUpdate memory settlementStateUpdate = signStateUpdate(settlementAck);

        data[3] = keccak256(abi.encode(settlementStateUpdate));

        // Propose state root as validator
        vm.startPrank(validator);
        rollup.proposeStateRoot(merkleLib.getRoot(data));
        vm.stopPrank();

        FraudEngine.DoubleSpendProofInput[2] memory doubleSpendProof;
        doubleSpendProof[0] = FraudEngine.DoubleSpendProofInput(
            Id.wrap(1), tradeStateUpdate, merkleLib.getProof(data, 2), keccak256(abi.encode(inputsA[0])), 0, true, true
        );
        doubleSpendProof[1] = FraudEngine.DoubleSpendProofInput(
            Id.wrap(1),
            settlementStateUpdate,
            merkleLib.getProof(data, 3),
            keccak256(abi.encode(inputsA[0])),
            0,
            false,
            true
        );

        fraudEngine.proveDoubleSpendInput(doubleSpendProof);

        // State root should be flagged as fraudulent
        assert(rollup.fraudulent(merkleLib.getRoot(data)));
    }

    function test_reportDoubleSpendOutput() external {
        // Merkle Tree that will hold signed state updates
        bytes32[] memory data = new bytes32[](4);

        StateUpdateLibrary.UTXO[] memory inputsA = new StateUpdateLibrary.UTXO[](1);
        StateUpdateLibrary.UTXO[] memory inputsB = new StateUpdateLibrary.UTXO[](1);
        bytes32[] memory hashedInputsA = new bytes32[](1);

        StateUpdateLibrary.UTXO[] memory outputsA = new StateUpdateLibrary.UTXO[](1);
        StateUpdateLibrary.Deposit memory depositA = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, 1 ether, ID_ZERO, Id.wrap(block.chainid)
        );
        {
            StateUpdateLibrary.Deposit memory depositB = StateUpdateLibrary.Deposit(
                bob, address(token), participatingInterface, 1 ether, ID_ONE, Id.wrap(block.chainid)
            );

            inputsA[0] = depositToUtxo(depositA, 0);
            inputsB[0] = depositToUtxo(depositB, 1);
            data[0] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositA, 0)))));
            data[1] = keccak256(abi.encode((signStateUpdate(depositStateUpdate(depositB, 1)))));
        }

        StateUpdateLibrary.SignedStateUpdate memory tradeStateUpdate;

        {
            bytes32[] memory hashedInputsB = new bytes32[](1);
            hashedInputsA[0] = keccak256(abi.encode(inputsA[0]));
            hashedInputsB[0] = keccak256(abi.encode(inputsB[0]));
            StateUpdateLibrary.UTXO[] memory outputsB = new StateUpdateLibrary.UTXO[](1);

            bytes32[] memory hashedOutputsA = new bytes32[](1);
            // reuse the output of the deposit
            hashedOutputsA[0] = keccak256(abi.encode(inputsA[0]));
            bytes32[] memory hashedOutputsB = new bytes32[](1);
            hashedOutputsB[0] = keccak256(abi.encode(outputsB[0]));
            outputsB[0] = utxoToTradeUtxo({ _input: inputsB[0], _stateUpdateIdTrade: 2, _recipient: alice });

            // Create trade object
            uint256 size = 1 ether;
            uint256 price = 1;
            StateUpdateLibrary.Product memory product =
                StateUpdateLibrary.Product(address(0), block.chainid, address(token), block.chainid);
            StateUpdateLibrary.Trade memory trade = StateUpdateLibrary.Trade(
                StateUpdateLibrary.TradeParams(
                    participatingInterface,
                    signOrder(StateUpdateLibrary.Order(product, true, size, price), aliceKey),
                    signOrder(StateUpdateLibrary.Order(product, false, size, price), bobKey),
                    product,
                    size,
                    price
                ),
                hashedInputsA,
                hashedInputsB,
                hashedOutputsA,
                hashedOutputsB
            );
            StateUpdateLibrary.StateUpdate memory t = tradeToStateUpdate(trade, 2);
            tradeStateUpdate = signStateUpdate(t);
        }

        data[2] = keccak256(abi.encode(tradeStateUpdate));

        // Re-use deposit as input to a settlement request
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(depositA.trader, depositA.asset, Id.wrap(3), Id.wrap(2), 3, hashedInputsA);
        StateUpdateLibrary.SignedStateUpdate memory settlementStateUpdate = signStateUpdate(settlementAck);

        data[3] = keccak256(abi.encode(settlementStateUpdate));

        // Propose state root as validator
        vm.startPrank(validator);
        rollup.proposeStateRoot(merkleLib.getRoot(data));
        vm.stopPrank();

        FraudEngine.DoubleSpendProofOutput[2] memory doubleSpendProof;
        doubleSpendProof[0] = FraudEngine.DoubleSpendProofOutput(
            Id.wrap(1),
            signStateUpdate(depositStateUpdate(depositA, 0)),
            merkleLib.getProof(data, 0),
            keccak256(abi.encode(inputsA[0])),
            0,
            false,
            true
        );
        doubleSpendProof[1] = FraudEngine.DoubleSpendProofOutput(
            Id.wrap(1), tradeStateUpdate, merkleLib.getProof(data, 2), keccak256(abi.encode(inputsA[0])), 0, true, true
        );

        fraudEngine.proveDoubleSpendOutput(doubleSpendProof);

        // State root should be flagged as fraudulent
        assert(rollup.fraudulent(merkleLib.getRoot(data)));
    }
}
