// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Manager/BaseManager.sol";
import "../src/Manager/ChildManager.sol";
import "@LayerZero/mocks/LZEndpointMock.sol";
import "../src/CrossChain/LayerZero/AssetChainLz.sol";
import "../src/CrossChain/LayerZero/ProcessingChainLz.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "../src/Staking/Staking.sol";
import "../src/util/Signature.sol";
import "@murky/Merkle.sol";

contract DeployBaseChain is Script {
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    BaseManager internal manager;
    ChildManager internal assetChainManager;

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
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(block.chainid), uint64(_amount)),
            StateUpdateLibrary.Balance(_trader, _token, Id.wrap(block.chainid), 0)
        );
        return StateUpdateLibrary.StateUpdate(
            StateUpdateLibrary.TYPE_ID_Settlement,
            Id.wrap(_stateUpdateId),
            participatingInterface,
            abi.encode(settlement)
        );
    }

    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        uint256 alicePk = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        uint256 bobPk = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        // string[] memory chainNames = new string[](1);
        // Id[] memory chainIds = new Id[](1);
        // chainNames[0] = "Polygon";
        // chainIds[0] = Id.wrap(2501);
        vm.startBroadcast(deployerPrivateKey);
        participatingInterface = vm.addr(deployerPrivateKey);
        admin = vm.addr(deployerPrivateKey);
        validator = vm.addr(deployerPrivateKey);
        manager = new BaseManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            // TODO: should be deployed in script or passed as env var
            _stablecoin: address(0),
            _protocolToken: address(0)
        });
        {
            LZEndpointMock lzEndpointMock = new LZEndpointMock(uint16(block.chainid));
            LZEndpointMock lzEndpointMockDest = new LZEndpointMock(uint16(block.chainid));
            manager.deployRelayer(address(lzEndpointMock));
            // TODO: replace with mock lz endpoint
            // TODO: set trusted remotes
            ProcessingChainLz processingChainLz = ProcessingChainLz(manager.relayer());
            assetChainManager = new ChildManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _relayer: manager.relayer()
        });
            assetChainManager.deployReceiver(address(lzEndpointMockDest), uint16(block.chainid));
            processingChainLz.setTrustedRemote(
                uint16(block.chainid), abi.encodePacked(assetChainManager.receiver(), address(processingChainLz))
            );
            uint256[] memory evm = new uint256[](1);
            uint16[] memory lz = new uint16[](1);
            evm[0] = block.chainid;
            lz[0] = uint16(block.chainid);
            processingChainLz.setChainIds(evm, lz);
            address[] memory dests = new address[](1);
            dests[0] = assetChainManager.receiver();
            processingChainLz.setPortalAddress(evm, dests);
            AssetChainLz assetChainLz = AssetChainLz(assetChainManager.receiver());
            assetChainLz.setTrustedRemote(
                uint16(block.chainid), abi.encodePacked(address(processingChainLz), address(assetChainLz))
            );
            lzEndpointMock.setDestLzEndpoint(address(assetChainLz), address(lzEndpointMockDest));
            ERC20PresetFixedSupply stablecoin =
                new ERC20PresetFixedSupply("Stablecoin", "USDT", 10_000 ether, validator);
            ERC20PresetFixedSupply protocolToken =
                new ERC20PresetFixedSupply("ProtocolToken", "TXA", 10_000 ether, validator);

            Staking staking = new Staking(address(manager), address(stablecoin), address(protocolToken));
            manager.setCollateral(address(staking));
            uint256[3] memory tranches = staking.getActiveTranches();
            protocolToken.approve(manager.collateral(), 10_000 ether);
            stablecoin.approve(manager.collateral(), 10_000 ether);
            staking.stake(address(stablecoin), 10_000 ether, tranches[1]);
            staking.stake(address(protocolToken), 10_000 ether, tranches[1]);

            vm.stopBroadcast();
        }

        // deposit as alice and bob
        {
            Portal portal = Portal(assetChainManager.portal());

            // Depoist native asset as Alice and bob
            vm.startBroadcast(alicePk);
            portal.depositNativeAsset{ value: 1 ether }();
            vm.stopBroadcast();

            vm.startBroadcast(bobPk);
            portal.depositNativeAsset{ value: 1 ether }();
            vm.stopBroadcast();
        }

        // report settlement
        StateUpdateLibrary.StateUpdate memory settlementAck =
            settlementStateUpdate(validator, address(0), Id.wrap(0), Id.wrap(0), 0, 1000e6);
        Signature sig = new Signature(participatingInterface);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(deployerPrivateKey, sig.typeHashStateUpdate(settlementAck));
        StateUpdateLibrary.SignedStateUpdate memory stateUpdate =
            StateUpdateLibrary.SignedStateUpdate(settlementAck, v, r, s);

        Rollup rollup = Rollup(manager.rollup());

        bytes32[] memory proof;
        bytes32 stateRoot;

        // Construct merkle tree of signed state updates
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encode(stateUpdate));
        data[1] = keccak256(abi.encode(stateUpdate));

        // Get state root and proof of the signed state update with settlement message
        proof = m.getProof(data, 0);
        stateRoot = m.getRoot(data);

        vm.startBroadcast(deployerPrivateKey);
        rollup.submitSettlement{ value: 0.07 ether }({ _stateRoot: stateRoot, _signedUpdate: stateUpdate, _proof: proof });

        vm.stopBroadcast();

        string memory obj1 = '{"manager":"","portal":"","rollup":""}';
        vm.serializeAddress(obj1, "portal", assetChainManager.portal());
        vm.serializeAddress(obj1, "rollup", manager.rollup());
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(manager)), "./out/contracts.json");
    }
}
