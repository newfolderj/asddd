// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../src/Manager/AssetChain/AssetChainManager.sol";
import "@LayerZero/mocks/LZEndpointMock.sol";
import "../src/CrossChain/LayerZero/AssetChainLz.sol";
import "../src/CrossChain/LayerZero/ProcessingChainLz.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "../src/Staking/Staking.sol";
import "../src/Oracle/Oracle.sol";
import "../src/util/helpers/Token.sol";

contract DeployBaseChain is Script {
    using stdJson for string;

    address internal participatingInterface;
    address internal admin;
    address internal validator;

    ProcessingChainManager internal manager;
    AssetChainManager internal assetChainManager;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/token_accounts.json");
        string memory json = vm.readFile(path);
        address[] memory airdrop = json.readAddressArray("$");
        vm.startBroadcast(deployerPrivateKey);
        participatingInterface = vm.addr(deployerPrivateKey);
        admin = vm.addr(deployerPrivateKey);
        validator = vm.addr(deployerPrivateKey);
        Token stablecoin = new Token(airdrop, "Stablecoin", "USDT", 6, 500_000e6);
        Token protocolToken = new Token(airdrop, "ProtocolToken", "TXA", 18, 10_000_000e18);

        manager = new ProcessingChainManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _stablecoin: address(stablecoin),
            _protocolToken: address(protocolToken)
        });
        manager.addSupportedChain(block.chainid);
        manager.addSupportedAsset(block.chainid, address(0), 18);
        manager.addSupportedAsset(block.chainid, address(stablecoin), 6);
        // Setup oracle with initial prices
        manager.deployOracle(address(stablecoin), block.chainid, 0.3e18);
        Oracle oracle = Oracle(manager.oracle());
        oracle.grantReporter(admin);
        oracle.initializePrice(block.chainid, address(0), 1667e18);

        LZEndpointMock lzEndpointMock = new LZEndpointMock(uint16(block.chainid));
        LZEndpointMock lzEndpointMockDest = new LZEndpointMock(uint16(block.chainid));
        manager.deployRelayer(address(lzEndpointMock));
        ProcessingChainLz processingChainLz = ProcessingChainLz(manager.relayer());
        assetChainManager = new AssetChainManager({
            _participatingInterface: participatingInterface, 
            _admin: admin
        });
        assetChainManager.addSupportedAsset(address(0), address(0));
        stablecoin.approve(address(assetChainManager), 1);
        assetChainManager.addSupportedAsset(address(stablecoin), validator);
        assetChainManager.deployReceiver(address(lzEndpointMockDest), uint16(block.chainid));
        processingChainLz.setTrustedRemote(
            uint16(block.chainid), abi.encodePacked(assetChainManager.receiver(), address(processingChainLz))
        );
        uint256[] memory evm = new uint256[](1);
        uint16[] memory lz = new uint16[](1);
        evm[0] = block.chainid;
        lz[0] = uint16(block.chainid);
        processingChainLz.setChainIds(evm, lz);
        AssetChainLz assetChainLz = AssetChainLz(assetChainManager.receiver());
        assetChainLz.setTrustedRemote(
            uint16(block.chainid), abi.encodePacked(address(processingChainLz), address(assetChainLz))
        );
        lzEndpointMock.setDestLzEndpoint(address(assetChainLz), address(lzEndpointMockDest));

        Staking staking = new Staking(address(manager), address(stablecoin), address(protocolToken));
        manager.setStaking(address(staking));
        uint256[3] memory tranches = staking.getActiveTranches();
        protocolToken.approve(manager.staking(), 400_000e18);
        stablecoin.approve(manager.staking(), 100_000e6);
        staking.stake(address(stablecoin), 100_000e6, tranches[2]);
        staking.stake(address(protocolToken), 400_000e18, tranches[2]);

        vm.stopBroadcast();

        string memory obj1 =
            '{"manager":"","assetManager":"","portal":"","rollup":"","oracle":"","staking":"","protolToken":"","stablecoin":""}';
        vm.serializeAddress(obj1, "portal", assetChainManager.portal());
        vm.serializeAddress(obj1, "rollup", manager.rollup());
        vm.serializeAddress(obj1, "oracle", manager.oracle());
        vm.serializeAddress(obj1, "staking", manager.staking());
        vm.serializeAddress(obj1, "protocolToken", manager.protocolToken());
        vm.serializeAddress(obj1, "stablecoin", manager.stablecoin());
        vm.serializeAddress(obj1, "assetManager", address(assetChainManager));
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(manager)), string.concat("./out/contracts_", vm.toString(block.chainid), ".json"));
    }
}
