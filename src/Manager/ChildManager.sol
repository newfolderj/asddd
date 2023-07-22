// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./Manager.sol";
import "./IChildManager.sol";
import "../CrossChain/LayerZero/AssetChainLz.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ChildManager is Manager, IChildManager {
    address public immutable relayer;
    address public immutable portal;
    address public receiver;

    mapping(address => bool) public supportedAsset;

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

    /// Called by the admin to add a support for a new asset on this chain.
    /// If the asset is an ERC20 token, it performs a basic sanity check on the token contract.
    /// If an asset is added here, it should also be added on the processing chain's manager.
    /// @param _asset Address of the asset being added (with address(0) representing the native asset)
    /// @param _approved Address that has approved this contract to transfer 1 wei of the asset
    function addSupportedAsset(address _asset, address _approved) external {
        if (msg.sender != admin) revert("Only admin");
        if (supportedAsset[_asset]) revert("Asset already supported");
        if (_asset != address(0)) {
            IERC20Metadata asset = IERC20Metadata(_asset);
            if (asset.decimals() == 0) revert();
            uint256 balance = asset.balanceOf(address(this));
            require(asset.transferFrom(_approved, address(this), 1), "Failed to transferFrom _approved to manager contract");
            require(asset.balanceOf(address(this)) == balance + 1, "transferFrom didn't update manager contract's balance correctly");
            require(asset.transfer(_approved, 1) , "Failed to transfer token back to _approved");
            require(asset.balanceOf(address(this)) == balance, "transfer failed to update manager contract's balance correctly");
        }
        supportedAsset[_asset] = true;
    }

}
