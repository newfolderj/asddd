// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/BaseManager.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";

contract AddSupportedAssetProcessing is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnProcessingChain();
        string memory json = vm.readFile(processingChainContractsPath);
        BaseManager manager = BaseManager(abi.decode(json.parseRaw(".manager"), (address)));
        Oracle oracle = Oracle(manager.oracle());

        // Get all assets for this chain ID
        json = vm.readFile(assetsPath);
        bytes[] memory assets = abi.decode(json.parseRaw("$"), (bytes[]));
        for (uint256 i = 0; i < assets.length; i++) {
            Asset memory asset = abi.decode(vm.parseJson(json,string.concat(".[", vm.toString(i), "]") ), (Asset));
            uint256 initialPrice = vm.parseJsonUint(json, string.concat(".[", vm.toString(i), "].initialPrice"));
            // Skip assets that are already supported
            if (manager.isSupportedAsset(vm.envUint("ASSET_CHAINID"), asset.tokenAddress)) {
                continue;
            }
            if (asset.tokenAddress != address(0)) {
                console.log(string.concat("Adding support for asset on chain ID ", vm.envString("ASSET_CHAINID")));
                vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
                manager.addSupportedAsset(vm.envUint("ASSET_CHAINID"), asset.tokenAddress,uint8(asset.precision));
                vm.stopBroadcast();
            } else {
                console.log(
                    string.concat("Adding support for native asset on chain ID ", vm.envString("ASSET_CHAINID"))
                );
                vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
                manager.addSupportedAsset(vm.envUint("ASSET_CHAINID"), address(0), uint8(asset.precision));
                vm.stopBroadcast();
            }
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
            uint256 usdPrice = initialPrice / 1e18;
            if (usdPrice == 0) {
                usdPrice = initialPrice / 1e16;
                if (usdPrice == 0) {
                    console.log(string.concat("Setting price for symbol ", asset.symbol, " to less than a cent."));
                } else {
                    console.log(
                        string.concat(
                            "Setting price for symbol ", asset.symbol, " to ~", vm.toString(usdPrice), " cents."
                        )
                    );
                }
            } else {
                console.log(
                    string.concat(
                        "Setting price for symbol ", asset.symbol, " to ~", vm.toString(usdPrice), " dollars."
                    )
                );
            }
            oracle.initializePrice(vm.envUint("ASSET_CHAINID"), asset.tokenAddress, initialPrice);
            vm.stopBroadcast();
        }
    }
}
