// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

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

contract DecodeStakingLogs is Script {
    using stdJson for string;
    mapping(address => uint256) internal totals;

    function run() external {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/staking_data.json");
        string memory json = vm.readFile(path);
        bytes memory stakingData = json.parseRaw("$");
        // console.log(stakingData.length);
        
        for(uint256 i = 0; i < 12; i++) {
            bytes[] memory decoded = json.readBytesArray(string.concat(".[", vm.toString(i), "]"));
            address staker = abi.decode(decoded[0], (address));
            address asset = abi.decode(decoded[1], (address));
            (uint256 amount, uint256 unlockTime, uint256 depositId) = abi.decode(decoded[2], (uint256, uint256, uint256));
            // console.log("-----");
            // console.log(string.concat("staker: ", vm.toString(staker)));
            // console.log(string.concat("asset: ", vm.toString(asset)));
            // console.log(string.concat("amount: ", vm.toString(amount)));
            // console.log(string.concat("unlockTime: ", vm.toString(unlockTime)));
            // console.log(string.concat("depositId: ", vm.toString(depositId)));

            console.log(
                string.concat(
                    "_credit(",
                    vm.toString(staker), ",",
                    vm.toString(asset), ",",
                    vm.toString(amount), ",",
                    vm.toString(unlockTime),
                    ");"
                )
            );
            totals[asset] += amount;
        }
        
        console.log(string.concat("total usdt: ", vm.toString(totals[0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9])));
        console.log(string.concat("total txa : ", vm.toString(totals[0xca84a842116d741190c3782e94fa9b7B7bbcf31b])));
    }
}
