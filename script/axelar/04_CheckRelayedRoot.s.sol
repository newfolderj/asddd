// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../../src/Manager/ChildManager.sol";

contract CheckRelayedRoot is Script {
    using stdJson for string;

    ChildManager internal manager;

    function run() external {
        // get receiver address
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/axelar/out/receiver.json");
        string memory json = vm.readFile(path);
        address _receiver = abi.decode(json.parseRaw(".receiver"), (address));
        manager = ChildManager(address(Receiver(_receiver).manager()));
        
        Rollup rollup = Rollup(manager.rollup());
        Id epoch = rollup.epoch();
        require(epoch == ID_ONE);
        bytes32 stateRoot = rollup.getConfirmedStateRoot(0);
        require(stateRoot == keccak256(abi.encode("Test")));
    }
}
