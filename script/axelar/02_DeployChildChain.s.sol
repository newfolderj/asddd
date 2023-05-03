// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../../src/Manager/ChildManager.sol";

contract DeployBaseChain is Script {
    using stdJson for string;

    address internal participatingInterface;
    address internal admin;
    address internal validator;

    ChildManager internal manager;

    function run() external {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/axelar/out/relayer.json");
        string memory json = vm.readFile(path);
        address relayer = abi.decode(json.parseRaw(".relayer"), (address));

        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);
        participatingInterface = vm.addr(deployerPrivateKey);
        admin = vm.addr(deployerPrivateKey);
        validator = vm.addr(deployerPrivateKey);
        manager = new ChildManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _relayer: relayer,
            _baseChain: "Ethereum"
        });
        manager.deployReceiver({
            _axelarGateway: vm.envAddress("AXELAR_GATEWAY"),
            _axelarGasReceiver: vm.envAddress("AXELAR_GAS_RECEIVER")
        });
        vm.stopBroadcast();

        vm.writeJson(vm.serializeAddress("", "receiver", manager.receiver()), "./axelar/out/receiver.json");
    }
}
