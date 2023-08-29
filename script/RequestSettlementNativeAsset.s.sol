// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/Portal/Portal.sol";

contract RequestSettlementNativeAsset is Script {
    using stdJson for string;

    function run() external {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/out/contracts.json");
        string memory json = vm.readFile(path);
        address portalAddress = abi.decode(json.parseRaw(".portal"), (address));
        uint256 alicePk = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        uint256 bobPk = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        Portal portal = Portal(portalAddress);

        // Depoist native asset as Alice and bob
        vm.startBroadcast(alicePk);
        portal.requestSettlement(address(0));
        vm.stopBroadcast();

        vm.startBroadcast(bobPk);
        portal.requestSettlement(address(0));
        vm.stopBroadcast();
    }
}
