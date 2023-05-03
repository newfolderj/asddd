// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../../src/Manager/BaseManager.sol";

contract RelayStateRoot is Script {
    using stdJson for string;

    BaseManager internal manager;

    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        // get receiver address
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/axelar/out/receiver.json");
        string memory json = vm.readFile(path);
        address receiver = abi.decode(json.parseRaw(".receiver"), (address));

        path = string.concat(root, "/axelar/out/relayer.json");
        json = vm.readFile(path);
        Relayer relayer = Relayer(abi.decode(json.parseRaw(".relayer"), (address)));
        manager = BaseManager(abi.decode(json.parseRaw(".manager"), (address)));

        // set receiver in manager
        address[] memory receivers = new address[](1);
        uint256[] memory chainIds = new uint256[](1);
        receivers[0] = receiver;
        chainIds[0] = 2501;
        vm.startBroadcast(deployerPrivateKey);
        manager.setReceivers(chainIds, receivers);

        // request settlement
        Portal portal = Portal(manager.portal());
        portal.requestSettlement(address(0));

        // report state root
        Rollup rollup = Rollup(manager.rollup());
        rollup.proposeStateRoot(keccak256(abi.encode("Test")));
        // relay state root
        relayer.relayStateRoot{ value: 0.05 ether }(Id.wrap(2501), Id.wrap(0));
        vm.stopBroadcast();
    }
}
