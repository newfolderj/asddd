// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";

contract DeployProcessingChain is BaseDeploy {
    using stdJson for string;


    function run() external {
        onlyOnProcessingChain();
        address protocolTokenProcessingChain = vm.envAddress("PROTOCOL_TOKEN_ADDR");

        address stablecoin = vm.envAddress("STABLECOIN_ASSET_ADDR");
        address stablecoinProcessingChain = vm.envAddress("STABLECOIN_ADDR");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address participatingInterface = vm.addr(deployerPrivateKey);
        address admin = vm.addr(deployerPrivateKey);
        address validator = vm.addr(deployerPrivateKey);
        // Deploy Manager
        ProcessingChainManager manager = new ProcessingChainManager({
            _participatingInterface: participatingInterface, 
            _admin: admin,
            _validator: validator,
            _stablecoin: stablecoinProcessingChain,
            _protocolToken: protocolTokenProcessingChain
        });
        // Deploy LZ Relayer
        manager.deployRelayer(vm.envAddress("LZ_ENDPOINT_PROCESSING"));

        // Deploy Staking
        Staking staking =
            new Staking(address(manager), address(stablecoinProcessingChain), address(protocolTokenProcessingChain));
        manager.setStaking(address(staking));

        // Deploy Oracle
        manager.deployOracle(address(stablecoin), block.chainid, vm.envUint("PROTOCOL_TOKEN_PRICE"));
        Oracle oracle = Oracle(manager.oracle());
        oracle.grantReporter(admin);
        oracle.grantReporter(vm.envAddress("ORACLE_REPORTER_ADDR"));
        vm.stopBroadcast();

        string memory obj1 = '{}';
        vm.serializeAddress(obj1, "rollup", manager.rollup());
        vm.serializeAddress(obj1, "processingChainLz", manager.relayer());
        vm.serializeAddress(obj1, "oracle", manager.oracle());
        vm.serializeAddress(obj1, "staking", manager.staking());
        vm.writeJson(vm.serializeAddress(obj1, "manager", address(manager)), processingChainContractsPath);
    }
}
