// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/AssetChain/AssetChainManager.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/CrossChain/LayerZero/AssetChainLz.sol";

contract UpdateTrustedRemote is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnAssetChain();
        string memory json = vm.readFile(assetChainContractsPath);
        AssetChainManager manager = AssetChainManager(abi.decode(json.parseRaw(".manager"), (address)));
        json = vm.readFile(processingChainContractsPath);
        address relayer = abi.decode(json.parseRaw(".processingChainLz"), (address));
        AssetChainLz receiver = AssetChainLz(manager.receiver());
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        receiver.setTrustedRemote(
            uint16(vm.envUint("LZ_CHAINID_PROCESSING")), abi.encodePacked(relayer, address(receiver))
        );
        vm.stopBroadcast();
    }
}
