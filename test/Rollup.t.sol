// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Test } from "forge-std/Test.sol";

import "../src/Manager/Manager.sol";
// import "../src/Portal/Portal.sol";
// import "../src/Portal/Rollup.sol";
import "../src/util/Signature.sol";
import "@openzeppelin/token/ERC20/ERC20.sol";
import "@murky/Merkle.sol";

contract RollupTest is Test {
    using IdLib for Id;

    uint256 internal piKey = 0xEC;
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    Manager internal manager;
    Portal internal portal;
    Rollup internal rollup;

    Signature internal sigUtil;

    address internal alice;
    address internal bob;

    ERC20 internal token;

    event DepositUtxo(
        address wallet, uint256 amount, address token, address participatingInterface, Id chainSequenceId, bytes32 utxo
    );

    function depositUtxo(
        StateUpdateLibrary.Deposit memory _deposit,
        uint256 _stateUpdateId
    )
        internal
        returns (StateUpdateLibrary.UTXO memory)
    {
        return StateUpdateLibrary.UTXO(
            _deposit.trader,
            _deposit.amount,
            _stateUpdateId,
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
            keccak256(abi.encode(_deposit)),
            _deposit.participatingInterface,
            _deposit.asset,
            _deposit.chainId
        );
    }

    function depositStateUpdate(
        address _trader,
        address _token,
        uint256 _amount,
        Id _chainSequenceId,
        uint256 _stateUpdateId
    )
        internal
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            _trader, _token, participatingInterface, _amount, _chainSequenceId, Id.wrap(block.chainid)
        );
        StateUpdateLibrary.UTXO memory utxo = depositUtxo(deposit, _stateUpdateId);
        StateUpdateLibrary.DepositAcknowledgement memory depositAck = StateUpdateLibrary.DepositAcknowledgement(
            deposit, keccak256(abi.encode(deposit)), keccak256(abi.encode(utxo))
        );
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_DepositAcknowledgement,
            Id.wrap(_stateUpdateId),
            participatingInterface,
            abi.encode(depositAck)
        );
    }

    function depositStateUpdate(
        StateUpdateLibrary.Deposit memory _deposit,
        uint256 _stateUpdateId
    )
        internal
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        StateUpdateLibrary.UTXO memory utxo = depositUtxo(_deposit, _stateUpdateId);
        StateUpdateLibrary.DepositAcknowledgement memory depositAck = StateUpdateLibrary.DepositAcknowledgement(
            _deposit, keccak256(abi.encode(_deposit)), keccak256(abi.encode(utxo))
        );
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_DepositAcknowledgement,
            Id.wrap(_stateUpdateId),
            participatingInterface,
            abi.encode(depositAck)
        );
    }

    function settlementStateUpdate(
        address _trader,
        address _token,
        Id _chainSequenceId,
        Id _settlementId,
        uint256 _stateUpdateId,
        bytes32[] memory inputs
    )
        internal
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        StateUpdateLibrary.SettlementRequest memory settlementRequest = StateUpdateLibrary.SettlementRequest(
            _trader, _token, participatingInterface, _chainSequenceId, Id.wrap(block.chainid), _settlementId
        );
        StateUpdateLibrary.Settlement memory settlement = StateUpdateLibrary.Settlement(settlementRequest, inputs);
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_Settlement,
            Id.wrap(_stateUpdateId),
            participatingInterface,
            abi.encode(settlement)
        );
    }

    function signStateUpdate(StateUpdateLibrary.StateUpdate memory _stateUpdate)
        internal
        returns (StateUpdateLibrary.SignedStateUpdate memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(piKey, sigUtil.typeHashStateUpdate(_stateUpdate));
        return StateUpdateLibrary.SignedStateUpdate(_stateUpdate, v, r, s);
    }

    function setUp() public virtual {
        participatingInterface = vm.addr(piKey);
        admin = vm.addr(0xAD);
        validator = vm.addr(0xDA);

        manager = new Manager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator
        });
        portal = Portal(manager.portal());
        rollup = Rollup(manager.rollup());

        alice = vm.addr(0xA11CE);
        bob = vm.addr(0xB0B);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        token = new ERC20("TestToken", "TST");

        sigUtil = new Signature(participatingInterface);
    }

    function test_processSettlement() external {
        StateUpdateLibrary.UTXO[] memory inputs = new StateUpdateLibrary.UTXO[](1);
        bytes32[] memory hashedInputs = new bytes32[](1);

        // Alice makes the first deposit
        uint256 amount = 0.5 ether;
        vm.prank(alice);
        portal.depositNativeAsset{value: amount}();

        // Create corresponding Deposit and UTXO objects
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            alice, address(0), participatingInterface, amount, ID_ZERO, Id.wrap(block.chainid)
        );
        inputs[0] = depositUtxo(deposit, 0);
        hashedInputs[0] = keccak256(abi.encode(inputs[0]));

        // Bob makes some deposits
        vm.startPrank(bob);
        portal.depositNativeAsset{value: 1 ether}();
        portal.depositNativeAsset{value: 1.5 ether}();
        vm.stopPrank();

        // Alice requests settlement
        vm.prank(alice);
        portal.requestSettlement(address(0));

        // Create settlement request object
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(deposit.trader, deposit.asset, Id.wrap(3), Id.wrap(2), 3, hashedInputs);
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

        // Report settlement as the validator
        vm.prank(validator);
        rollup.processSettlement({
            _stateRoot: stateRoot,
            _settlementAcknowledgement: stateUpdate,
            _proof: proof,
            _inputs: inputs
        });

        // Alice can now withdraw original deposit
        vm.prank(alice);
        portal.withdraw({_amount: amount, _token: address(0)});
    }
}
