// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "../CrossChainFunctions.sol";
import "./IProcessingChainLz.sol";
import "../../Manager/ProcessingChain/IProcessingChainManager.sol";
import "@LayerZero/lzApp/NonblockingLzApp.sol";

/**
 * Deploys on the processing chain and handles sending/receiving messages using LayerZero
 */
contract ProcessingChainLz is NonblockingLzApp, IProcessingChainLz, CrossChainFunctions {
    IProcessingChainManager public manager;
    address zroPaymentAddress;

    // Maps EVM chain ID to LayerZero chain ID
    mapping(uint256 => uint16) chainIds;
    mapping(uint256 => address) portals;

    constructor(address _lzEndpoint, address _owner, address _manager) NonblockingLzApp(_lzEndpoint) {
        _transferOwnership(_owner);
        manager = IProcessingChainManager(_manager);
    }

    function setChainIds(uint256[] calldata evmChainId, uint16[] calldata lzChainId) external onlyOwner {
        if (evmChainId.length != lzChainId.length) revert("Lengths of chain ID arrays don't match");
        for (uint256 i = 0; i < evmChainId.length; i++) {
            chainIds[evmChainId[i]] = lzChainId[i];
        }
    }

    function setPaymentZeroAddress(address _zroPaymentAddress) external onlyOwner { 
        zroPaymentAddress = _zroPaymentAddress;
    }

    // Send obligations to Portal via AssetChainLz on specified chain
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
        if (!(msg.sender == manager.rollup() || msg.sender == manager.staking())) {
            revert("Sender must be Rollup or Staking contract");
        }
        uint16 lzChainId = chainIds[_chainId];
        if (lzChainId == 0) revert("LzChainId not set");
        bytes memory payload = abi.encode(CrossChainMessage(WRITE_OBLIGATIONS, abi.encode(_obligations)));
        _lzSend(lzChainId, payload, payable(_refundAddress), zroPaymentAddress, _adapterParams, msg.value);
    }

    function sendDepositRejections(
        uint256 _chainId,
        bytes32[] calldata _depositHashes,
        bytes calldata _adapterParams,
        address _refundAddress
    )
        external
        payable
    {
        if (msg.sender != manager.rollup()) revert();
        uint16 lzChainId = chainIds[_chainId];
        if (lzChainId == 0) revert("LzChainId not set");
        bytes memory payload = abi.encode(CrossChainMessage(REJECT_DEPOSITS, abi.encode(_depositHashes)));
        _lzSend(lzChainId, payload, payable(_refundAddress), zroPaymentAddress, _adapterParams, msg.value);
    }

    // ProcessingChainLz does not receive any data from AssetChainLz
    function _nonblockingLzReceive(uint16, bytes memory, uint64, /*_nonce*/ bytes memory) internal override { }
}
