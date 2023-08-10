// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import "../../src/Manager/BaseManager.sol";
import "../../src/Manager/ChildManager.sol";
import "../../src/Staking/Staking.sol";
import "../../src/Rollup/FraudEngine.sol";
import "../../src/util/Signature.sol";
import "../../src/Oracle/Oracle.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@murky/Merkle.sol";
import "@LayerZero/mocks/LZEndpointMock.sol";
import "../../src/CrossChain/LayerZero/AssetChainLz.sol";
import "forge-std/console.sol";

contract BaseTest is Test {
    using IdLib for Id;

    uint256 internal piKey = 0xEC;
    uint256 internal aliceKey = 0xA11CE;
    uint256 internal bobKey = 0xB0B;
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    BaseManager internal manager;
    ChildManager internal assetChainManager;
    Portal internal portal;
    Rollup internal rollup;
    Staking internal staking;
    FraudEngine internal fraudEngine;
    ProcessingChainLz internal processingChainLz;
    AssetChainLz internal assetChainLz;
    LZEndpointMock internal lzEndpointMock;
    LZEndpointMock internal lzEndpointMockDest;

    Signature internal sigUtil;
    Merkle internal merkleLib;

    address internal alice;
    address internal bob;

    ERC20 internal token;
    ERC20 internal stablecoin;
    ERC20 internal protocolToken;

    uint256 internal chainId = 1;

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
            _trader, _token, participatingInterface, _amount, _chainSequenceId, Id.wrap(chainId)
        );
        StateUpdateLibrary.Balance memory balance =
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(chainId), _amount);
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
            StateUpdateLibrary.Balance(_deposit.trader, _deposit.asset, Id.wrap(chainId), _deposit.amount);
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
            _trader, _token, participatingInterface, _chainSequenceId, Id.wrap(chainId)
        );
        StateUpdateLibrary.Settlement memory settlement = StateUpdateLibrary.Settlement(
            settlementRequest,
            ID_ZERO,
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(chainId), _amount),
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(chainId), 0)
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
        vm.roll(17752520);
        participatingInterface = vm.addr(piKey);
        admin = vm.addr(0xAD);
        validator = vm.addr(0xDA);

        stablecoin = new ERC20("Stablecoin", "USDT");
        protocolToken = new ERC20("ProtocolToken", "TXA"); 
        token = new ERC20("TestToken", "TST");

        manager = new BaseManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _stablecoin: address(stablecoin),
            _protocolToken: address(protocolToken)
        });
        rollup = Rollup(manager.rollup());
        vm.startPrank(admin);
        fraudEngine = new FraudEngine(participatingInterface, address(manager));
        staking = new Staking(address(manager), address(stablecoin), address(protocolToken));
        manager.setFraudEngine(address(fraudEngine));
        manager.setCollateral(address(staking));
        lzEndpointMock = new LZEndpointMock(uint16(block.chainid));
        lzEndpointMockDest = new LZEndpointMock(uint16(chainId));
        manager.deployRelayer(address(lzEndpointMock));
        // TODO: replace with mock lz endpoint
        // TODO: set trusted remotes
        processingChainLz = ProcessingChainLz(manager.relayer());
        uint256[] memory evmChainId = new uint256[](1);
        evmChainId[0] = chainId;
        uint16[] memory lzChainId = new uint16[](1);
        lzChainId[0] = uint16(chainId);
        processingChainLz.setChainIds(evmChainId, lzChainId);
        assetChainManager = new ChildManager(participatingInterface, admin, validator, manager.relayer());
        assetChainManager.deployReceiver(address(lzEndpointMockDest), uint16(block.chainid));
        portal = Portal(assetChainManager.portal());
        assetChainLz = AssetChainLz(assetChainManager.receiver());
        address[] memory portals = new address[](1);
        portals[0] = address(portal);
        processingChainLz.setPortalAddress(evmChainId, portals);
        processingChainLz.setTrustedRemoteAddress(uint16(chainId), abi.encodePacked(address(assetChainLz)));
        assetChainLz.setTrustedRemoteAddress(uint16(block.chainid), abi.encodePacked(address(processingChainLz)));
        lzEndpointMock.setDestLzEndpoint(address(assetChainLz), address(lzEndpointMockDest));
        // lzEndpointMockDest.setDestLzEndpoint(address(assetChainLz), address(lzEndpointMockDest));
        // Setup initial supported assets
        assetChainManager.addSupportedAsset(address(0), address(0));
        deal({ token: address(token), to: admin, give: 1});
        token.approve(address(assetChainManager), 1);
        assetChainManager.addSupportedAsset(address(token), admin);
        manager.addSupportedChain(chainId);
        manager.addSupportedAsset(chainId, address(0), 18);
        manager.addSupportedAsset(chainId, address(token), 18);
        // Setup oracle with initial prices
        manager.deployOracle(address(token), chainId, 0.3e18);
        Oracle oracle = Oracle(manager.oracle());
        oracle.grantReporter(admin);
        oracle.initializePrice(chainId, address(0), 1895.25e18);
        vm.stopPrank();

        alice = vm.addr(aliceKey);
        bob = vm.addr(bobKey);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(validator, 10 ether);


        sigUtil = new Signature(participatingInterface);
        merkleLib = new Merkle();

        deal({ token: address(protocolToken), to: validator, give: 20_000 ether });
        deal({ token: address(stablecoin), to: validator, give: 500 ether });
        uint256[3] memory tranches = staking.getActiveTranches();
        console.log(tranches[0]);
        console.log(tranches[1]);
        console.log(tranches[2]);
        vm.startPrank(validator);
        protocolToken.approve(manager.collateral(), 20_000 ether);
        stablecoin.approve(manager.collateral(), 500 ether);
        staking.stake(address(stablecoin), 500 ether, tranches[0]);
        staking.stake(address(protocolToken), 20_000 ether, tranches[0]);
        vm.stopPrank();
    }
}
