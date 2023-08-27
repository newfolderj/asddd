// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../src/Manager/AssetChain/AssetChainManager.sol";
import "@LayerZero/mocks/LZEndpointMock.sol";
import "../src/CrossChain/LayerZero/AssetChainLz.sol";
import "../src/CrossChain/LayerZero/ProcessingChainLz.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "../src/Staking/Staking.sol";
import "../src/Oracle/Oracle.sol";
import "../src/util/helpers/Token.sol";

contract DeployBUSD is Script {
    using stdJson for string;

    address internal participatingInterface;
    address internal admin;
    address internal validator;

    ProcessingChainManager internal manager;
    AssetChainManager internal assetChainManager;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/token_accounts.json");
        string memory json = vm.readFile(path);
        address[] memory airdrop = json.readAddressArray("$");
        vm.startBroadcast(deployerPrivateKey);
        Token busd = new Token(airdrop, "BinanceUSD", "BUSD", 18, 5_000_000e18);
        Token usdt = new Token(airdrop, "TetherUSD", "USDT", 6, 5_000_000e6);
        console.log(address(busd));
        console.log(address(usdt));
        vm.stopBroadcast();
    }
}
