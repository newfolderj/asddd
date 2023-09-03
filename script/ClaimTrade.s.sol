// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Manager/BaseManager.sol";

contract ClaimTrade is Script {
    using stdJson for string;

    function run() external {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/out/contracts.json");
        string memory json = vm.readFile(path);
        address dummyCoin = abi.decode(json.parseRaw(".dummyCoin"), (address));
        Portal portal = Portal(abi.decode(json.parseRaw(".portal"), (address)));
        Rollup rollup = Rollup(abi.decode(json.parseRaw(".rollup"), (address)));
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        // IERC20 dummyCoin = IERC20(abi.decode(json.parseRaw(".dummyCoin"), (address)));

        // Depoist native asset as Alice and bob
        vm.roll(block.number + 1_999_999);
        vm.startBroadcast(deployerPrivateKey);
        rollup.confirmStateRoot();
        rollup.confirmStateRoot();
        bytes memory tradeProof = vm.envBytes("TRADE_PROOF");
        Rollup.TradeProof memory proof = abi.decode(tradeProof, (Rollup.TradeProof));
        Rollup.TradeProof[] memory proofs = new Rollup.TradeProof[](1);
        proofs[0] = proof;
        uint256 epoch = Id.unwrap(rollup.lastConfirmedEpoch());
        Rollup.TradingFeeClaim memory claim = Rollup.TradingFeeClaim(epoch, proofs);
        Rollup.TradingFeeClaim[] memory claims = new Rollup.TradingFeeClaim[](1);
        claims[0] = claim;
        rollup.claimTradingFees(claims);
        address[] memory assets = new address[](2);
        assets[0] = address(0);
        assets[1] = address(dummyCoin);

        uint256 ethFees = rollup.tradingFees(Id.wrap(block.chainid),address(0));
        uint256 dmcFees = rollup.tradingFees(Id.wrap(block.chainid),dummyCoin);
        rollup.relayTradingFees{ value: 0.1 ether }(block.chainid, assets);

        portal.withdraw(ethFees, address(0));
        portal.withdraw(dmcFees, dummyCoin);

        vm.stopBroadcast();
    }
}
