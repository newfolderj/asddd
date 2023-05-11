// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./Manager.sol";
import "../Rollup/ChildRollup.sol";
import "./IChildManager.sol";
import "../CrossChain/Receiver.sol";

contract ChildManager is Manager, IChildManager {
    address public immutable rollup;
    address public immutable relayer;
    address public receiver;
    string public baseChain;

    constructor(
        address _participatingInterface,
        address _admin,
        address _validator,
        address _relayer,
        string memory _baseChain
    )
        Manager(_participatingInterface, _admin, _validator)
    {
        relayer = _relayer;
        rollup = address(new ChildRollup(_participatingInterface, address(this)));
        baseChain = _baseChain;
    }

    function deployReceiver(address _axelarGateway, address _axelarGasReceiver) external {
        if (msg.sender != admin) revert();
        if (receiver != address(0)) revert();
        receiver = address(
            new Receiver(
            address(this),
            _axelarGateway,
            _axelarGasReceiver,
            baseChain
            )
        );
    }
}
