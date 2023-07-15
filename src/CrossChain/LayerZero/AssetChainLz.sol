// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../../Rollup/IRollup.sol";
import "../../Portal/IPortal.sol";
import "../../Manager/IChildManager.sol";
import "../../StateUpdateLibrary.sol";
import "../../util/Id.sol";
import "@LayerZero/lzApp/NonblockingLzApp.sol";

/**
 * Deploys on the asset chain and handles sending/receiving messages using LayerZero
 */
contract AssetChainLz is NonblockingLzApp {
    address public manager;
    address public immutable processingChainSender;
    uint16 public immutable processingChainId;

    constructor(
        address _admin,
        address _lzEndpoint,
        address _processingChainSender,
        uint16 _processingChainId
    )
        NonblockingLzApp(_lzEndpoint)
    {
        // We expect this contract to be deployed through the asset chain manager
        manager = msg.sender;
        _transferOwnership(_admin);
        processingChainSender = _processingChainSender;
        processingChainId = _processingChainId;
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    )
        internal
        override
    {
        if (_srcChainId != processingChainId) revert();
        (address receiver, IPortal.Obligation[] memory obligations) = abi.decode(_payload, (address, IPortal.Obligation[]));
        IPortal( IChildManager(manager).portal()).writeObligations(obligations);
    }
}
