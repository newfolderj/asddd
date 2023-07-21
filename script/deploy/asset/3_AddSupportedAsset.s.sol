// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ChildManager.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";

contract AddSupportedAsset is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnAssetChain();
        string memory json = vm.readFile(assetChainContractsPath);
        ChildManager manager = ChildManager(abi.decode(json.parseRaw(".manager"), (address)));

        // Get all assets for this chain ID
        json = vm.readFile(assetsPath);
        bytes[] memory assets = abi.decode(json.parseRaw("$"), (bytes[]));
        console.log(assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            Asset memory asset = abi.decode(vm.parseJson(json,string.concat(".[", vm.toString(i), "]") ), (Asset));
            // Skip assets that are already supported
            if (manager.supportedAsset(asset.tokenAddress)) {
                continue;
            }
            if (asset.tokenAddress != address(0)) {
                IERC20Metadata token = IERC20Metadata(asset.tokenAddress);
                string memory symbol = token.symbol();
                if (keccak256(abi.encode(symbol)) != keccak256(abi.encode(asset.symbol))) {
                    revert(
                        string.concat("Symbol in assets.json does not match on-chain symbol for asset ", asset.symbol)
                    );
                }
                uint8 precision = token.decimals();
                console.log(precision);
                console.log(asset.precision);
                if (precision != asset.precision) {
                    revert(
                        string.concat("Precision in assets.json does not match on-chain precision for asset ", symbol)
                    );
                }
                if (token.allowance(vm.envAddress("APPROVER"), address(manager)) < 1) {
                    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
                    try token.approve(address(manager), 1) { }
                    catch {
                        revert(
                            string.concat(
                                "Manager needs to be approved to transfer ", symbol, " from ", vm.envString("APPROVER")
                            )
                        );
                    }
                    vm.stopBroadcast();
                }
                console.log(
                    string.concat("Adding support for asset ", symbol, " on chain ID ", vm.envString("ASSET_CHAINID"))
                );
                vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
                token.approve(address(manager), 1);
                manager.addSupportedAsset(address(token), vm.envAddress("APPROVER"));
                vm.stopBroadcast();
            } else {
                console.log(
                    string.concat("Adding support for native asset on chain ID ", vm.envString("ASSET_CHAINID"))
                );
                vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
                manager.addSupportedAsset(address(0), address(0));
                vm.stopBroadcast();
            }
        }
    }
}
