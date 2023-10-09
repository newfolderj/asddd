// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../BaseDeploy.sol";
import "../../../src/Manager/ProcessingChain/ProcessingChainManager.sol";
import "../../../src/Staking/Staking.sol";
import "../../../src/Rollup/Rollup.sol";
import "../../../src/Oracle/Oracle.sol";
import "../../../src/CrossChain/LayerZero/ProcessingChainLz.sol";
import "@murky/Merkle.sol";

contract SubmitSettlement is BaseDeploy {
    using stdJson for string;

    Rollup rollup;
    Staking staking;
    Oracle oracle;

    IERC20 stablecoin;
    IERC20 protocolToken;

    function run() external {
        onlyOnProcessingChain();
        string memory json = vm.readFile(processingChainContractsPath);
        ProcessingChainManager manager = ProcessingChainManager(abi.decode(json.parseRaw(".manager"), (address)));
        rollup = Rollup(manager.rollup());
        staking = Staking(manager.staking());
        oracle = Oracle(manager.oracle());

        stablecoin = IERC20(manager.stablecoin());
        protocolToken = IERC20(manager.protocolToken());
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
                            vm.envAddress("PROTOCOL_TOKEN_ADDR"),
                            manager.participatingInterface(),
                            ID_ONE,
                            Id.wrap(vm.envUint("ASSET_CHAINID"))
                        ),
                        ID_ONE,
                        StateUpdateLibrary.Balance(
                            vm.envAddress("VALIDATOR_ADDR"), vm.envAddress("PROTOCOL_TOKEN_ADDR"), Id.wrap(vm.envUint("ASSET_CHAINID")), 0.001 ether
                        ),
                        StateUpdateLibrary.Balance(
                            vm.envAddress("VALIDATOR_ADDR"), vm.envAddress("PROTOCOL_TOKEN_ADDR"), Id.wrap(vm.envUint("ASSET_CHAINID")), 0
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
        manager.grantValidator(manager.admin());
        // approve staking in stablecoin and protocol
        // stablecoin.approve(address(staking), 10_000e6);
        // protocolToken.approve(address(staking), 50_000e18);
        // stake into furthest tranche
        // staking.stake({ _asset: address(stablecoin), _amount: 10_000e6, _unlockTime: tranches[2] });
        // staking.stake({ _asset: address(protocolToken), _amount: 50_000e18, _unlockTime: tranches[2] });
        // propose a state root
        // bytes32 proposedRoot = rollup.proposedStateRoot(Id.wrap(Id.unwrap(rollup.epoch()) - 1));
        // rollup.submitSettlement(proposedRoot, stateRoot);
        // check if oracle prices need to be updated
        // check if price of asset being settled has expired
        // uint256 lastReport = oracle.lastReport(vm.envUint("ASSET_CHAINID"), address(0));
        // if (block.number > lastReport + oracle.PRICE_EXPIRY()) {
        //     oracle.report(vm.envUint("ASSET_CHAINID"), address(0), 1888.77e18, true);
        // }
        // check if price of protocol token has expired
        // lastReport = oracle.lastReport(vm.envUint("PROCESSING_CHAINID"), address(protocolToken));
        // if (block.number > lastReport + oracle.PRICE_EXPIRY()) {
            // oracle.report(vm.envUint("PROCESSING_CHAINID"), address(protocolToken), vm.envUint("PROTOCOL_TOKEN_PRICE"), true);
        // }
        // process a settlement
        rollup.submitSettlement{ value: 0.03 ether }(stateRoot, settlementStateUpdate, proof);

        vm.stopBroadcast();
    }
}
