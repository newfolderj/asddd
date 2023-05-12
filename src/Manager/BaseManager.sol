// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./Manager.sol";
import "../Rollup/Rollup.sol";
import "../Rollup/FraudEngine.sol";
import "./IBaseManager.sol";
import "../CrossChain/Relayer.sol";

contract BaseManager is Manager, IBaseManager {
    address public immutable rollup;
    address public relayer;

    mapping(uint256 => address) public receivers;

    constructor(
        address _participatingInterface,
        address _admin,
        address _validator
    )
        Manager(_participatingInterface, _admin, _validator)
    { 
        rollup = address(new FraudEngine(_participatingInterface, address(this)));
    }

    function deployRelayer(
        address _axelarGateway,
        address _axelarGasReceiver,
        string[] memory _chainNames,
        Id[] memory _chainIds
    )
        external
    {
        if (msg.sender != admin) revert();
        if (relayer != address(0)) revert();
        relayer = address(
            new Relayer(
                    address(this),
            _axelarGateway,
            _axelarGasReceiver,
            _chainNames,
            _chainIds
            )
        );
    }

    function setReceivers(uint256[] calldata _chainIds, address[] calldata _receivers) external {
        if (msg.sender != admin) revert();
        if (_chainIds.length != _receivers.length) revert();

        for (uint256 i = 0; i < _chainIds.length; i++) {
            receivers[_chainIds[i]] = _receivers[i];
        }
    }

    function getReceiverAddress(uint256 _chainId) external view returns (address) {
        return receivers[_chainId];
    }
}
