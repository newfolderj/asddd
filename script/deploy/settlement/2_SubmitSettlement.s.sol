// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";
import "@murky/Merkle.sol";

contract SubmitSettlement is BaseDeploy {
    using stdJson for string;

    function run() external {
        onlyOnProcessingChain();
        string memory json = vm.readFile(processingChainContractsPath);
        ProcessingChainManager manager = ProcessingChainManager(abi.decode(json.parseRaw(".manager"), (address)));
        Rollup rollup = Rollup(manager.rollup());
        Staking staking = Staking(manager.staking());

        IERC20 stablecoin = IERC20(manager.stablecoin());
        IERC20 protocolToken = IERC20(manager.protocolToken());
        uint256[3] memory tranches = staking.getActiveTranches();
        Id epoch = rollup.epoch();

        // Create settlement update
        StateUpdateLibrary.SignedStateUpdate memory settlementStateUpdate = StateUpdateLibrary.SignedStateUpdate(
            StateUpdateLibrary.StateUpdate(
                StateUpdateLibrary.TYPE_ID_Settlement,
                ID_ONE,
                manager.participatingInterface(),
                abi.encode(
                    StateUpdateLibrary.Settlement(
                        StateUpdateLibrary.SettlementRequest(
                            vm.envAddress("VALIDATOR_ADDR"),
                            address(0),
                            manager.participatingInterface(),
                            ID_ONE,
                            Id.wrap(vm.envUint("ASSET_CHAINID"))
                        ),
                        ID_ONE,
                        StateUpdateLibrary.Balance(
                            vm.envAddress("VALIDATOR_ADDR"), address(0), Id.wrap(vm.envUint("ASSET_CHAINID")), 1 ether
                        ),
                        StateUpdateLibrary.Balance(
                            vm.envAddress("VALIDATOR_ADDR"), address(0), Id.wrap(vm.envUint("ASSET_CHAINID")), 0
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
        // approve staking in stablecoin and protocol
        stablecoin.approve(address(staking), 10_000e6);
        protocolToken.approve(address(staking), 50_000e18);
        // stake into furthest tranche
        staking.stake({ _asset: address(stablecoin), _amount: 10_000e6, _unlockTime: tranches[2] });
        staking.stake({ _asset: address(protocolToken), _amount: 50_000e18, _unlockTime: tranches[2] });
        // propose a state root
        rollup.proposeStateRoot(stateRoot);
        // process a settlement
        rollup.processSettlements{ value: 0.5 ether }(Id.wrap(vm.envUint("ASSET_CHAINID")), params);

        vm.stopBroadcast();
    }
}
