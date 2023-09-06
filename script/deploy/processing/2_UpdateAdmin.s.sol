// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";

contract AddSupportedAssetProcessing is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnProcessingChain();
        string memory json = vm.readFile(processingChainContractsPath);
        ProcessingChainManager manager = ProcessingChainManager(abi.decode(json.parseRaw(".manager"), (address)));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        manager.transferAdmin(vm.envAddress("ADMIN_ADDR"));
        vm.stopBroadcast();
    }
}
