// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../../../src/Manager/AssetChain/AssetChainManager.sol";
import "../../../src/Rollup/Rollup.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";
import "@murky/Merkle.sol";

contract AddArbAssetChain is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnProcessingChain();
        address protocolTokenProcessingChain = vm.envAddress("PROTOCOL_TOKEN_ADDR");
        address stablecoinProcessingChain = vm.envAddress("STABLECOIN_ADDR");
        string memory json = vm.readFile(processingChainContractsPath);
        ProcessingChainManager manager = ProcessingChainManager(abi.decode(json.parseRaw(".manager"), (address)));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // Deploy AssetChainManager
        AssetChainManager assetChainManager = new AssetChainManager(
            manager.participatingInterface(),
            manager.admin()
        );
        // Deploy ProcessingChainLz
        ProcessingChainLz relayer = new ProcessingChainLz(
            vm.envAddress("LZ_ENDPOINT_PROCESSING"),
            manager.admin(),
            address(manager),
            address(assetChainManager)
        );
        console.log("Updated relayer");
        console.log(address(relayer));
        // Update relayer in processing chain manager
        manager.replaceRelayer(address(relayer));
        // Set ProcessingChainLz as receiver on AssetChainManager
        assetChainManager.replaceReceiver(address(relayer));
        // Add supported chain on processingchainmanager
        manager.addSupportedChain(block.chainid);
        // Add ProtocolToken as supported asset
        manager.addSupportedAsset(block.chainid, protocolTokenProcessingChain, 18);
        IERC20 protocolToken = IERC20(protocolTokenProcessingChain);
        protocolToken.approve(address(assetChainManager), 1);
        assetChainManager.addSupportedAsset(protocolTokenProcessingChain, vm.addr(vm.envUint("PRIVATE_KEY")));

        vm.stopBroadcast();
    }
}
