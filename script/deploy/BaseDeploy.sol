// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract BaseDeploy is Script {
    using stdJson for string;

    string processingChainContractsPath;
    string assetChainContractsPath;
    string assetsPath;

    uint256 processingChainId;

    struct Asset {
        uint256 initialPrice;
        uint256 precision;
        string symbol;
        address tokenAddress;
    }

    constructor() {
        processingChainId = vm.envUint("PROCESSING_CHAINID");
        string memory root = vm.projectRoot();
        processingChainContractsPath = string.concat(
            root, "/script/deploy/chains/", vm.envString("PROCESSING_CHAINID"), "/processingChainContracts.json"
        );
        assetChainContractsPath =
            string.concat(root, "/script/deploy/chains/", vm.envString("ASSET_CHAINID"), "/assetChainContracts.json");
        assetsPath = string.concat(root, "/script/deploy/chains/", vm.envString("ASSET_CHAINID"), "/assets.json");
    }

    function onlyOnAssetChain() internal view {
        if(block.chainid != vm.envUint("ASSET_CHAINID")) revert("Running script on wrong network.");
    }

    function onlyOnProcessingChain() internal view {
        if(block.chainid != vm.envUint("PROCESSING_CHAINID")) revert("Running script on wrong network.");
    }

}
