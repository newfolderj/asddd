// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Manager/BaseManager.sol";

contract DeployBaseChain is Script {
    address internal participatingInterface;
    address internal admin;
    address internal validator;

    BaseManager internal manager;

    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        uint256 alicePk = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        uint256 bobPk = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        // string[] memory chainNames = new string[](1);
        // Id[] memory chainIds = new Id[](1);
        // chainNames[0] = "Polygon";
        // chainIds[0] = Id.wrap(2501);
        vm.startBroadcast(deployerPrivateKey);
        participatingInterface = vm.addr(deployerPrivateKey);
        admin = vm.addr(deployerPrivateKey);
        validator = vm.addr(deployerPrivateKey);
        manager = new BaseManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            // TODO: should be deployed in script or passed as env var
            _stablecoin: address(0),
            _protocolToken: address(0)
        });
        // manager.deployRelayer({
        //     _axelarGateway: vm.envAddress("AXELAR_GATEWAY"),
        //     _axelarGasReceiver: vm.envAddress("AXELAR_GAS_RECEIVER"),
        //     _chainNames: chainNames,
        //     _chainIds: chainIds
        // });
        vm.stopBroadcast();

        string memory obj1 = '{"manager":"","portal":"","rollup":""}';
        vm.serializeAddress(obj1, "portal", manager.portal());
        vm.serializeAddress(obj1, "rollup", manager.rollup());
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(manager)), "./out/contracts.json");
    }
}
