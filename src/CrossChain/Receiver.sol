// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../Rollup/IRollup.sol";
import "../Rollup/IChildRollup.sol";
import "../Portal/IPortal.sol";
import "../Manager/IChildManager.sol";
import "../Manager/IManager.sol";
import "../StateUpdateLibrary.sol";
import "../util/Id.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";
import { AxelarExecutable } from "@axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { IAxelarGateway } from "@axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { StringToAddress, AddressToString } from "@axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";

/**
 * The Receiver contract receives confirmed state roots from the base chain.
 */
contract Receiver is AxelarExecutable {
    using AddressToString for address;
    using StringToAddress for string;
    using IdLib for Id;

    error INVALID_SOURCE_CHAIN();
    error CALLER_NOT_RELAYER();
    error EPOCH_OUT_OF_SEQUENCE(Id expectedEpoch, Id attemptedEpoch);

    struct RelayPayload {
        Id epoch;
        bytes32 stateRoot;
    }

    address public immutable manager;
    IAxelarGasService public immutable gasService;
    bytes32 baseChain;

    constructor(
        address _manager,
        address _axelarGateway,
        address _axelarGasReceiver,
        string memory _baseChain
    )
        AxelarExecutable(_axelarGateway)
    {
        gasService = IAxelarGasService(_axelarGasReceiver);
        manager = _manager;
        baseChain = keccak256(abi.encodePacked(_baseChain));
    }

    // AxelarExecutable
    function _execute(
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    )
        internal
        override
    {
        if (keccak256(abi.encodePacked(_sourceChain)) != baseChain) {
            revert INVALID_SOURCE_CHAIN();
        }
        if (_sourceAddress.toAddress() != IChildManager(manager).relayer()) {
            revert CALLER_NOT_RELAYER();
        }
        RelayPayload memory payload = abi.decode(_payload, (RelayPayload));
        address rollup = IManager(manager).rollup();
        Id currentEpoch = Id.wrap(IRollup(rollup).getCurrentEpoch());
        if (payload.epoch != currentEpoch) {
            revert EPOCH_OUT_OF_SEQUENCE(currentEpoch, payload.epoch);
        }

        // Send state root to rollup contract
        IChildRollup(rollup).receiveStateRoot(payload.stateRoot);

        // Relay ack back to base chain
        gateway.callContract(_sourceChain, _sourceAddress, abi.encode(payload));
    }
}
