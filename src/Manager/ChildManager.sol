// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./Manager.sol";
import "./IChildManager.sol";
import "../CrossChain/LayerZero/AssetChainLz.sol";

contract ChildManager is Manager, IChildManager {
    address public immutable relayer;
    address public immutable portal;
    address public receiver;

    constructor(
        address _participatingInterface,
        address _admin,
        address _validator,
        address _relayer
    )
        Manager(_participatingInterface, _admin, _validator)
    {
        relayer = _relayer;
        portal = address(new Portal(_participatingInterface, address(this)));
    }

    function deployReceiver(address _lzEndpoint, uint16 _lzProcessingChainId) external {
        if (msg.sender != admin) revert();
        if (receiver != address(0)) revert();
        receiver = address(
            new AssetChainLz(
            admin,
            _lzEndpoint,
            relayer,
            _lzProcessingChainId
            )
        );
    }
}
