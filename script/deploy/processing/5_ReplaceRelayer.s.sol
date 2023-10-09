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
        
        manager.replaceRelayer(0xBeab28AcAC919A58b4148401EbA4B4870839a7d8);
        vm.stopBroadcast();
    }
}
