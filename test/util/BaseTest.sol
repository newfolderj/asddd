// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import "../../src/Manager/BaseManager.sol";
import "../../src/Rollup/Collateral.sol";
import "../../src/Rollup/FraudEngine.sol";
import "../../src/util/Signature.sol";
import "@openzeppelin/token/ERC20/ERC20.sol";
import "@murky/Merkle.sol";

contract BaseTest is Test {
    using IdLib for Id;

    uint256 internal piKey = 0xEC;
    uint256 internal aliceKey = 0xA11CE;
    uint256 internal bobKey = 0xB0B;
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    BaseManager internal manager;
    Portal internal portal;
    Rollup internal rollup;
    Collateral internal collateral;
    FraudEngine internal fraudEngine;

    Signature internal sigUtil;
    Merkle internal merkleLib;

    address internal alice;
    address internal bob;

    ERC20 internal token;
    ERC20 internal stablecoin;
    ERC20 internal protocolToken;

    event DepositUtxo(
        address wallet, uint256 amount, address token, address participatingInterface, Id chainSequenceId, bytes32 utxo
    );

    function depositToUtxo(
        StateUpdateLibrary.Deposit memory _deposit,
        uint256 _stateUpdateId
    )
        internal
        pure
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

    // Takes a deposit, and generates an output
    // granting the amount to another trader.
    function depositToTradeUtxo(
        StateUpdateLibrary.Deposit memory _deposit,
        uint256 _stateUpdateIdDeposit,
        uint256 _stateUpdateIdTrade,
        address _recipient
    )
        internal
        pure
        returns (StateUpdateLibrary.UTXO memory)
    {
        StateUpdateLibrary.UTXO memory depositUtxo = StateUpdateLibrary.UTXO(
            _deposit.trader,
            _deposit.amount,
            _stateUpdateIdDeposit,
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
            keccak256(abi.encode(_deposit)),
            _deposit.participatingInterface,
            _deposit.asset,
            _deposit.chainId
        );
        bytes32 depositHash = keccak256(abi.encode(depositUtxo));
        return StateUpdateLibrary.UTXO(
            _recipient,
            _deposit.amount,
            _stateUpdateIdTrade,
            depositHash,
            keccak256(abi.encode(_deposit)),
            _deposit.participatingInterface,
            _deposit.asset,
            _deposit.chainId
        );
    }

    function utxoToTradeUtxo(
        StateUpdateLibrary.UTXO memory _input,
        uint256 _stateUpdateIdTrade,
        address _recipient
    )
        internal
        pure
        returns (StateUpdateLibrary.UTXO memory)
    {
        return StateUpdateLibrary.UTXO(
            _recipient,
            _input.amount,
            _stateUpdateIdTrade,
            keccak256(abi.encode(_input)),
            _input.depositUtxo,
            _input.participatingInterface,
            _input.asset,
            _input.chainId
        );
    }

    // Note that this does not properly set balance or deposit root
    function depositStateUpdate(
        address _trader,
        address _token,
        uint256 _amount,
        Id _chainSequenceId,
        uint256 _stateUpdateId
    )
        internal
        view
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            _trader, _token, participatingInterface, _amount, _chainSequenceId, Id.wrap(block.chainid)
        );
        StateUpdateLibrary.Balance memory balance =
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(block.chainid), _amount);
        StateUpdateLibrary.DepositAcknowledgement memory depositAck = StateUpdateLibrary.DepositAcknowledgement(
            deposit, ID_ZERO, balance, balance, ID_ZERO, keccak256(abi.encode(0)), keccak256(abi.encode(0))
        );
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_DepositAcknowledgement,
            Id.wrap(_stateUpdateId),
            participatingInterface,
            abi.encode(depositAck)
        );
    }

    // Note that this does not properly set balance or deposit root
    function depositStateUpdate(
        StateUpdateLibrary.Deposit memory _deposit,
        uint256 _stateUpdateId
    )
        internal
        view
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        StateUpdateLibrary.Balance memory balance =
            StateUpdateLibrary.Balance(_deposit.trader, _deposit.asset, Id.wrap(block.chainid), _deposit.amount);
        StateUpdateLibrary.DepositAcknowledgement memory depositAck = StateUpdateLibrary.DepositAcknowledgement(
            _deposit, ID_ZERO, balance, balance, ID_ZERO, keccak256(abi.encode(0)), keccak256(abi.encode(0))
        );
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_DepositAcknowledgement,
            Id.wrap(_stateUpdateId),
            participatingInterface,
            abi.encode(depositAck)
        );
    }

    function tradeToStateUpdate(
        StateUpdateLibrary.Trade memory _trade,
        uint256 _stateUpdateId
    )
        internal
        view
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_Trade, Id.wrap(_stateUpdateId), participatingInterface, abi.encode(_trade)
        );
    }

    function settlementStateUpdate(
        address _trader,
        address _token,
        Id _chainSequenceId,
        Id _settlementId,
        uint256 _stateUpdateId,
        uint256 _amount
    )
        internal
        view
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        StateUpdateLibrary.SettlementRequest memory settlementRequest = StateUpdateLibrary.SettlementRequest(
            _trader, _token, participatingInterface, _chainSequenceId, Id.wrap(block.chainid), _settlementId
        );
        StateUpdateLibrary.Settlement memory settlement = StateUpdateLibrary.Settlement(
            settlementRequest,
            ID_ZERO,
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(block.chainid), _amount),
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(block.chainid), 0)
        );
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_Settlement,
            Id.wrap(_stateUpdateId),
            participatingInterface,
            abi.encode(settlement)
        );
    }

    function feeStateUpdate(
        uint256 _feeSequenceId,
        uint256 _newMakerFee,
        uint256 _newTakerFee,
        uint256 _lastFeeUpdate,
        uint256 _stateUpdateId
    )
        internal
        view
        returns (StateUpdateLibrary.StateUpdate memory)
    {
        StateUpdateLibrary.FeeUpdate memory feeUpdate =
            StateUpdateLibrary.FeeUpdate(_feeSequenceId, _newMakerFee, _newTakerFee, _lastFeeUpdate);
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_FeeUpdate, Id.wrap(_stateUpdateId), participatingInterface, abi.encode(feeUpdate)
        );
    }

    function signStateUpdate(StateUpdateLibrary.StateUpdate memory _stateUpdate)
        internal
        view
        returns (StateUpdateLibrary.SignedStateUpdate memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(piKey, sigUtil.typeHashStateUpdate(_stateUpdate));
        return StateUpdateLibrary.SignedStateUpdate(_stateUpdate, v, r, s);
    }

    function setUp() public virtual {
        participatingInterface = vm.addr(piKey);
        admin = vm.addr(0xAD);
        validator = vm.addr(0xDA);

        stablecoin = new ERC20("Stablecoin", "USDT");
        protocolToken = new ERC20("ProtocolToken", "TXA");

        manager = new BaseManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _stablecoin: address(stablecoin),
            _protocolToken: address(protocolToken)
        });
        portal = Portal(manager.portal());
        rollup = Rollup(manager.rollup());
        vm.startPrank(admin);
        fraudEngine = new FraudEngine(participatingInterface, address(manager));
        collateral =
            new Collateral(participatingInterface, address(manager), address(stablecoin), address(protocolToken));
        manager.setFraudEngine(address(fraudEngine));
        manager.setCollateral(address(collateral));
        vm.stopPrank();

        alice = vm.addr(aliceKey);
        bob = vm.addr(bobKey);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        token = new ERC20("TestToken", "TST");

        sigUtil = new Signature(participatingInterface);
        merkleLib = new Merkle();

        deal({ token: address(protocolToken), to: validator, give: 100 ether });
        deal({ token: address(stablecoin), to: validator, give: 200 ether });
        vm.startPrank(validator);
        protocolToken.approve(manager.collateral(), 100 ether);
        stablecoin.approve(manager.collateral(), 200 ether);
        collateral.stake(200 ether);
        vm.stopPrank();
    }
}
