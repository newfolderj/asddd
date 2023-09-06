// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/AssetChain/AssetChainManager.sol";
import "../../../src/CrossChain/LayerZero/AssetChainLz.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";

struct ChainInfo {
    uint256 chainId;
    uint16 lzChainId;
    address lzEndpoint;
    string name;
}

contract DeployAssetChain is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnAssetChain();
        string memory json = vm.readFile(processingChainContractsPath);
        address relayer = abi.decode(json.parseRaw(".processingChainLz"), (address));

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address participatingInterface = vm.envAddress("PARTICIPATING_INTERFACE_ADDR");
        address admin = vm.addr(deployerPrivateKey);

        // Deploy Asset Manager
        AssetChainManager assetChainManager = new AssetChainManager(participatingInterface, admin);

        // Deploy LZ Relayer
        assetChainManager.deployReceiver(vm.envAddress("LZ_ENDPOINT_ASSET"), uint16(vm.envUint("LZ_CHAINID_PROCESSING")));
        AssetChainLz assetChainLz = AssetChainLz(assetChainManager.receiver());

        // Set processing chain Relayer as trusted remote
        assetChainLz.setTrustedRemote(
            uint16(vm.envUint("LZ_CHAINID_PROCESSING")), abi.encodePacked(relayer, address(assetChainLz))
        );
        vm.stopBroadcast();

        // Write asset chain contracts to json file
        string memory obj1 = '{}';
        vm.serializeAddress(obj1, "portal", assetChainManager.portal());
        vm.serializeAddress(obj1, "assetChainLz", assetChainManager.receiver());
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(assetChainManager)), assetChainContractsPath);
    }
}
