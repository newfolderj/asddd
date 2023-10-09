// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../../../src/Manager/AssetChain/AssetChainManager.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/Rollup/Rollup.sol";
import "../../../src/Oracle/Oracle.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";

contract DeployProcessingChain is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnProcessingChain();
        address protocolTokenProcessingChain = vm.envAddress("PROTOCOL_TOKEN_ADDR");

        address stablecoin = vm.envAddress("STABLECOIN_ASSET_ADDR");
        address stablecoinProcessingChain = vm.envAddress("STABLECOIN_ADDR");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address participatingInterface = vm.envAddress("PARTICIPATING_INTERFACE_ADDR");
        address admin = vm.addr(deployerPrivateKey);
        address validator = vm.envAddress("VALIDATOR_ADDR");
        // Deploy Manager
        ProcessingChainManager manager = new ProcessingChainManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _stablecoin: stablecoinProcessingChain,
            _protocolToken: protocolTokenProcessingChain
        });
        AssetChainManager assetChainManager = new AssetChainManager(participatingInterface, admin);
        // Deploy rollup
        Rollup rollup = new Rollup(participatingInterface, address(manager));
        manager.replaceRollup(address(rollup));
        // Deploy LZ Relayer
        ProcessingChainLz relayer = new ProcessingChainLz(
            vm.envAddress("LZ_ENDPOINT_PROCESSING"),
            admin,
            address(manager),
            address(assetChainManager)
            );
        manager.replaceRelayer(address(relayer));
        manager.addSupportedChain(block.chainid);
        assetChainManager.replaceReceiver(address(relayer));
        // Add ProtocolToken as supported asset
        manager.addSupportedAsset(block.chainid, protocolTokenProcessingChain, 18);
        IERC20 protocolToken = IERC20(protocolTokenProcessingChain);
        protocolToken.approve(address(assetChainManager), 1);
        assetChainManager.addSupportedAsset(protocolTokenProcessingChain, vm.addr(vm.envUint("PRIVATE_KEY")));

        // Deploy Staking
        Staking staking =
            new Staking(address(manager), address(stablecoinProcessingChain), address(protocolTokenProcessingChain));
        manager.setStaking(address(staking));

        // Deploy Oracle
        Oracle oracle = new Oracle(
            admin, address(manager), protocolTokenProcessingChain, stablecoin, 1, vm.envUint("PROTOCOL_TOKEN_PRICE")
        );
        manager.replaceOracle(address(oracle));
        // manager.deployOracle(address(stablecoin), block.chainid, vm.envUint("PROTOCOL_TOKEN_PRICE"));
        // Oracle oracle = Oracle(manager.oracle());
        oracle.grantReporter(admin);
        oracle.grantReporter(vm.envAddress("ORACLE_REPORTER_ADDR"));
        vm.stopBroadcast();

        string memory obj1 = "{}";
        vm.serializeAddress(obj1, "rollup", manager.rollup());
        vm.serializeAddress(obj1, "processingChainLz", manager.relayer());
        vm.serializeAddress(obj1, "oracle", manager.oracle());
        vm.serializeAddress(obj1, "staking", manager.staking());
        vm.serializeAddress(obj1, "assetManager", address(assetChainManager));
        vm.serializeAddress(obj1, "portal", assetChainManager.portal());
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(manager)), processingChainContractsPath);

        // Write asset chain contracts to json file
        vm.serializeAddress(obj1, "assetChainLz", assetChainManager.receiver());
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(assetChainManager)), assetChainContractsPath);
    }
}
