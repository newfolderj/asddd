// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IProcessingChainLz.sol";
import "../../Rollup/IRollup.sol";
import "../../Manager/IBaseManager.sol";
import "../../StateUpdateLibrary.sol";
import "../../util/Id.sol";
import "@LayerZero/lzApp/NonblockingLzApp.sol";

/**
 * Deploys on the processing chain and handles sending/receiving messages using LayerZero
 */
contract ProcessingChainLz is NonblockingLzApp, IProcessingChainLz {
    address zroPaymentAddress;

    // Maps EVM chain ID to LayerZero chain ID
    mapping(uint256 => uint16) chainIds;
    mapping(uint256 => address) portals;

    constructor(address _lzEndpoint, address _owner) NonblockingLzApp(_lzEndpoint) {
        _transferOwnership(_owner);
    }

    function setChainIds(uint256[] calldata evmChainId, uint16[] calldata lzChainId) external onlyOwner {
        if (evmChainId.length != lzChainId.length) revert("Lengths of chain ID arrays don't match");
        for (uint256 i = 0; i < evmChainId.length; i++) {
            chainIds[evmChainId[i]] = lzChainId[i];
        }
    }

    function setPortalAddress(uint256[] calldata evmChainId, address[] calldata portal) external onlyOwner {
        if (evmChainId.length != portal.length) revert("Lengths of chain ID and portal arrays don't match");
        for (uint256 i = 0; i < evmChainId.length; i++) {
            portals[evmChainId[i]] = portal[i];
        }
    }

    // Send obligation to Portal on specified chain
    // Used after processing settlements, trading fees, and staking rewards
    function sendObligations(
        uint256 _chainId,
        IPortal.Obligation[] calldata _obligations,
        bytes calldata _adapterParams,
        address _refundAddress
    )
        external
        payable
    {
        uint16 lzChainId = chainIds[_chainId];
        bytes memory payload = abi.encode(portals[_chainId], _obligations);
        _lzSend(lzChainId, payload, payable(_refundAddress), zroPaymentAddress, _adapterParams, msg.value);
    }

    // TODO: handle receiving data
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    )
        internal
        override
    { }
}
