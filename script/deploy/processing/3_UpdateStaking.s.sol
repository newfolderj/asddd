// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../../../src/Rollup/Rollup.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";
import "@murky/Merkle.sol";

contract AddSupportedAssetProcessing is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnProcessingChain();
        address protocolTokenProcessingChain = vm.envAddress("PROTOCOL_TOKEN_ADDR");
        address stablecoinProcessingChain = vm.envAddress("STABLECOIN_ADDR");
        string memory json = vm.readFile(processingChainContractsPath);
        ProcessingChainManager manager = ProcessingChainManager(abi.decode(json.parseRaw(".manager"), (address)));


        Rollup rollup = Rollup(manager.rollup());
        Id epoch = rollup.epoch();

        // Create settlement update (just used in simulation to verify fix)
        StateUpdateLibrary.SignedStateUpdate memory settlementStateUpdate = StateUpdateLibrary.SignedStateUpdate(
            StateUpdateLibrary.StateUpdate(
                StateUpdateLibrary.TYPE_ID_Settlement,
                ID_ONE,
                manager.participatingInterface(),
                abi.encode(
                    StateUpdateLibrary.Settlement(
                        StateUpdateLibrary.SettlementRequest(
                            vm.envAddress("VALIDATOR_ADDR"),
                            address(0xdAC17F958D2ee523a2206206994597C13D831ec7),
                            manager.participatingInterface(),
                            Id.wrap(100),
                            Id.wrap(1)
                        ),
                        ID_ONE,
                        StateUpdateLibrary.Balance(
                            vm.envAddress("VALIDATOR_ADDR"), address(0xdAC17F958D2ee523a2206206994597C13D831ec7), Id.wrap(1), 11_450e6
                        ),
                        StateUpdateLibrary.Balance(
                            vm.envAddress("VALIDATOR_ADDR"), address(0xdAC17F958D2ee523a2206206994597C13D831ec7), Id.wrap(1), 0
                        )
                    )
                )
            ),
            0,
            keccak256("0"),
            keccak256("0")
        );

        // Create state root
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encode(settlementStateUpdate));
        data[1] = data[0];
        Merkle merkle = new Merkle();
        bytes32 stateRoot = merkle.getRoot(data);
        bytes32[] memory proof = merkle.getProof(data, 0);

        Rollup.SettlementParams[] memory params = new Rollup.SettlementParams[](1);
        params[0] = Rollup.SettlementParams(settlementStateUpdate, epoch, proof);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // Deploy Staking
        Staking staking =
            new Staking(address(manager), address(stablecoinProcessingChain), address(protocolTokenProcessingChain));
        manager.replaceStaking(address(staking));

        // Below only used in simulation to ensure new staking contract fixes issue
        // manager.grantValidator(vm.addr(vm.envUint("PRIVATE_KEY")));
        // console.log(block.number);
        // vm.roll(block.number + manager.fraudPeriod() + 100);
        // console.log(block.number);
        // uint256 availableBefore = staking.getAvailableToClaim(0xc789bBC077DDaa59B9dAc1fae6fDdDA20cC664d7, 1, 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        // rollup.submitSettlement{ value: 0.03 ether }(stateRoot, settlementStateUpdate, proof);
        // uint256 availableAfter = staking.getAvailableToClaim(0xc789bBC077DDaa59B9dAc1fae6fDdDA20cC664d7, 1, 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        // console.log("Matic reward before");
        // console.log(availableBefore);
        // console.log("Matic reward after");
        // console.log(availableAfter);


        vm.stopBroadcast();
    }
}
