// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../Rollup/IRollup.sol";
import "../Portal/IPortal.sol";
import "../Manager/IManager.sol";
import "../Manager/IBaseManager.sol";
import "../StateUpdateLibrary.sol";
import "../util/Id.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";
import { AxelarExecutable } from "@axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { IAxelarGateway } from "@axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { StringToAddress, AddressToString } from "@axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";

/**
 * The Relayer contract sends confirmed state roots from the base chain to child chains.
 */
contract Relayer is AxelarExecutable {
    using AddressToString for address;
    using IdLib for Id;

    uint256 internal constant MIN_GAS_STATE_ROOT_RELAY = 100_000;

    error CHAIN_ARRAY_MISMATCH(uint256 namesSize, uint256 idsSize);
    error SAME_CHAIN_INVALID();
    error CALLER_NOT_VALIDATOR();
    error EPOCH_OUT_OF_SEQUENCE(Id expectedEpoch, Id attemptedEpoch);
    error INVALID_STATE(RelayState expectedState, RelayState actualState);
    error UNSUPPORTED_CHAIN(Id chainId);
    error INSUFFICIENT_GAS();

    // Describes the state of an epoch for a chain
    enum RelayState {
        AWAITING, // No relay has been sent.
        SENT // A relay transaction has been sent but not confirmed
    }

    struct ChainRelayState {
        Id nextEpoch;
        RelayState state;
    }

    struct RelayPayload {
        uint256 epoch;
        bytes32 stateRoot;
    }

    // Maps chain IDs to the last epoch that was relayed
    mapping(Id => ChainRelayState) public relayState;

    IManager internal immutable manager;

    // Axelar
    IAxelarGasService public immutable gasService;
    mapping(bytes32 => Id) internal nameToChainId;
    mapping(Id => string) internal chainIdToName;

    constructor(
        address _manager,
        address _axelarGateway,
        address _axelarGasReceiver,
        string[] memory _chainNames,
        Id[] memory _chainIds
    )
        AxelarExecutable(_axelarGateway)
    {
        gasService = IAxelarGasService(_axelarGasReceiver);
        manager = IManager(_manager);

        if (_chainNames.length != _chainIds.length) revert CHAIN_ARRAY_MISMATCH(_chainNames.length, _chainIds.length);

        unchecked {
            for (uint256 i = 0; i < _chainNames.length; i++) {
                nameToChainId[keccak256(abi.encode(_chainNames[i]))] = _chainIds[i];
                chainIdToName[_chainIds[i]] = _chainNames[i];
            }
        }
    }

    struct Reward {
        address asset;
        uint256 amount;
    }

    function relayRewards(uint256 _chainId, Reward[] calldata _rewards) external { }

    function relayStateRoot(Id _chainId, Id _epoch) external payable {
        if (_epoch != relayState[_chainId].nextEpoch) {
            revert EPOCH_OUT_OF_SEQUENCE(relayState[_chainId].nextEpoch, _epoch);
        }

        if (relayState[_chainId].state != RelayState.AWAITING) {
            revert INVALID_STATE(RelayState.AWAITING, relayState[_chainId].state);
        }

        // We expect this call to revert in Rollup contract if state root for this epoch is not confirmed
        bytes32 stateRoot = IRollup(manager.rollup()).getConfirmedStateRoot(Id.unwrap(_epoch));

        _relay(stateRoot, _chainId, _epoch);

        relayState[_chainId].state = RelayState.SENT;
    }

    function _relay(bytes32 _stateRoot, Id _chainId, Id _epoch) internal {
        address reciever = IBaseManager(address(manager)).getReceiverAddress(Id.unwrap(_chainId));
        if (reciever == address(0)) revert UNSUPPORTED_CHAIN(_chainId);

        RelayPayload memory payload = RelayPayload(Id.unwrap(_epoch), _stateRoot);
        string memory chainName = chainIdToName[_chainId];

        if (msg.value < MIN_GAS_STATE_ROOT_RELAY) revert INSUFFICIENT_GAS();

        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this), chainName, reciever.toString(), abi.encode(payload), msg.sender
        );

        gateway.callContract(chainName, reciever.toString(), abi.encode(payload));
    }

    // TODO: relay obligation ( bytes32 utxo hash -> amount, address )

    // Axelar
    function _execute(string calldata _sourceChain, string calldata, bytes calldata _payload) internal override {
        RelayPayload memory payload = abi.decode(_payload, (RelayPayload));
        _confirmRelay(nameToChainId[keccak256(abi.encode(_sourceChain))], Id.wrap(payload.epoch));
    }

    function _confirmRelay(Id _chainId, Id _epoch) internal {
        if (_epoch != relayState[_chainId].nextEpoch) {
            revert EPOCH_OUT_OF_SEQUENCE(relayState[_chainId].nextEpoch, _epoch);
        }

        if (relayState[_chainId].state != RelayState.SENT) {
            revert INVALID_STATE(RelayState.SENT, relayState[_chainId].state);
        }

        relayState[_chainId].nextEpoch = relayState[_chainId].nextEpoch.increment();
        relayState[_chainId].state = RelayState.AWAITING;
    }
}
