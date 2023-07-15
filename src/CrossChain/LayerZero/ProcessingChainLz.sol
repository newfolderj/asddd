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

    constructor(address _lzEndpoint, address _owner) NonblockingLzApp(_lzEndpoint) {
        _transferOwnership(_owner);
    }

    // send reward to Portal on specified chain
    // send settlement to Portal on specified chain
    // send fee to Portal on specified chain

    // Send obligation to Portal on specified chain
    function sendObligations(
        uint256 _chainId,
        IPortal.Obligation[] calldata _obligations,
        bytes calldata _adapterParams,
        address _refundAddress
    )
        external
        payable
    {
        uint16 lzChainId = _getLzChainId(_chainId);
        bytes memory payload = abi.encode(_getPortal(_chainId), _obligations);
        _lzSend(lzChainId, payload, payable(_refundAddress), zroPaymentAddress, _adapterParams, msg.value);
    }

    function _getLzChainId(uint256 _chainId) internal returns (uint16) {
        // TODO: get the lz chain ID
        return uint16(_chainId);
    }

    function _getPortal(uint256 _chainId) internal returns (address) {
        // TODO: get address of Portal contract for given chain id
        return address(0);
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
