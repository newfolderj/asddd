// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../BaseDeploy.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "../../../src/Manager/BaseManager.sol";

contract AddSupportedChain is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnProcessingChain();
        string memory json = vm.readFile(assetChainContractsPath);
        address assetChainLz = abi.decode(json.parseRaw(".assetChainLz"), (address));
        json = vm.readFile(processingChainContractsPath);
        BaseManager manager = BaseManager(abi.decode(json.parseRaw(".manager"), (address)));
        ProcessingChainLz relayer = ProcessingChainLz(manager.relayer());

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // add trusted remote
        relayer.setTrustedRemote(
            uint16(vm.envUint("LZ_CHAINID_ASSET")), abi.encodePacked(assetChainLz, address(relayer))
        );

        // add chain ID and assetChainLz address
        uint256[] memory evm = new uint256[](1);
        uint16[] memory lz = new uint16[](1);
        evm[0] = vm.envUint("ASSET_CHAINID");
        lz[0] = uint16(vm.envUint("LZ_CHAINID_ASSET"));
        relayer.setChainIds(evm, lz);
        address[] memory dests = new address[](1);
        dests[0] = assetChainLz;
        relayer.setPortalAddress(evm, dests);

        // add supported chain
        manager.addSupportedChain(vm.envUint("ASSET_CHAINID"));
        vm.stopBroadcast();
    }
}
