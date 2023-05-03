// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../../src/Manager/BaseManager.sol";

contract CheckRelayAck is Script {
    using stdJson for string;

    function run() external view {
        // get relayer address
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/axelar/out/relayer.json");
        string memory json = vm.readFile(path);
        Relayer relayer = Relayer(abi.decode(json.parseRaw(".relayer"), (address)));

        // Check that ack was received from child chain
        (Id nextEpoch,) = relayer.relayState(Id.wrap(2501));
        require(nextEpoch == ID_ONE);
    }
}
