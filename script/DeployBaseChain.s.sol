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
import "../src/Oracle/Oracle.sol";

contract DeployBaseChain is Script {
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    BaseManager internal manager;
    ChildManager internal assetChainManager;

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
        ERC20PresetFixedSupply stablecoin = new ERC20PresetFixedSupply("Stablecoin", "USDT", 1e20 ether, validator);
        ERC20PresetFixedSupply protocolToken = new ERC20PresetFixedSupply("ProtocolToken", "TXA", 1e20 ether, validator);

        manager = new BaseManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _stablecoin: address(stablecoin),
            _protocolToken: address(protocolToken)
        });
        manager.addSupportedChain(block.chainid);
        manager.addSupportedAsset(block.chainid, address(0), 18);
        // Setup oracle with initial prices
        manager.deployOracle(address(stablecoin), block.chainid, 0.3e18);
        Oracle oracle = Oracle(manager.oracle());
        oracle.grantReporter(admin);
        oracle.initializePrice(block.chainid, address(0), 1895.25e18);

        LZEndpointMock lzEndpointMock = new LZEndpointMock(uint16(block.chainid));
        LZEndpointMock lzEndpointMockDest = new LZEndpointMock(uint16(block.chainid));
        manager.deployRelayer(address(lzEndpointMock));
        ProcessingChainLz processingChainLz = ProcessingChainLz(manager.relayer());
        assetChainManager = new ChildManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _relayer: manager.relayer()
        });
        assetChainManager.addSupportedAsset(address(0), address(0));
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

        Staking staking = new Staking(address(manager), address(stablecoin), address(protocolToken));
        manager.setCollateral(address(staking));
        uint256[3] memory tranches = staking.getActiveTranches();
        protocolToken.approve(manager.collateral(), 1e20 ether);
        stablecoin.approve(manager.collateral(), 1e20 ether);
        staking.stake(address(stablecoin), 1e20 ether, tranches[1]);
        staking.stake(address(protocolToken), 1e20 ether, tranches[1]);

        vm.stopBroadcast();

        string memory obj1 = '{"manager":"","portal":"","rollup":""}';
        vm.serializeAddress(obj1, "portal", assetChainManager.portal());
        vm.serializeAddress(obj1, "rollup", manager.rollup());
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(manager)), "./out/contracts.json");
    }
}
