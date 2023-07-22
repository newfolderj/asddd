// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./Manager.sol";
import "./FeeManager.sol";
import "./IBaseManager.sol";
import "../Rollup/Rollup.sol";
import "../CrossChain/LayerZero/ProcessingChainLz.sol";
import "../Portal/WalletDelegation.sol";

contract BaseManager is Manager, IBaseManager, FeeManager {
    address public immutable rollup;
    address public fraudEngine;
    address public collateral;
    address public immutable walletDelegation;
    address public relayer;
    address public oracle;

    /// Number of blocks that must pass after a state root is submitted before it can be confirmed.
    uint256 public fraudPeriod = 28_800; // ~ 4 days on Ethereum
    mapping(uint256 => address) public receivers;
    mapping(uint256 => bool) public supportedChains;
    mapping(uint256 => mapping(address => uint8)) public supportedAsset;

    constructor(
        address _participatingInterface,
        address _admin,
        address _validator,
        address _stablecoin,
        address _protocolToken
    )
        Manager(_participatingInterface, _admin, _validator)
    {
        rollup = address(new Rollup(_participatingInterface, address(this)));
        walletDelegation = address(new WalletDelegation(_participatingInterface, address(this)));
    }

    function deployRelayer(address _lzEndpoint) external {
        if (msg.sender != admin) revert();
        if (relayer != address(0)) revert();
        relayer = address(
            new ProcessingChainLz(
            _lzEndpoint,
            admin 
            )
        );
    }

    function setFraudEngine(address _fraudEngine) external {
        if (msg.sender != admin) revert();
        if (fraudEngine != address(0)) revert();
        fraudEngine = _fraudEngine;
    }

    function setCollateral(address _collateral) external {
        if (msg.sender != admin) revert();
        if (collateral != address(0)) revert();
        collateral = _collateral;
    }

    function setOracle(address _oracle) external {
        if (msg.sender != admin) revert();
        if (oracle != address(0)) revert();
        oracle = _oracle;
    }

    function setReceivers(uint256[] calldata _chainIds, address[] calldata _receivers) external {
        if (msg.sender != admin) revert();
        if (_chainIds.length != _receivers.length) revert();

        for (uint256 i = 0; i < _chainIds.length; i++) {
            receivers[_chainIds[i]] = _receivers[i];
        }
    }

    function addSupportedChain(uint256 _chainId) external {
        if (msg.sender != admin) revert();
        if (supportedChains[_chainId]) revert();
        supportedChains[_chainId] = true;
    }

    /// Called by admin to support a new asset on the protocol.
    /// If an asset is added here, it should also be added on the corresponding chain's manager.
    /// @param _chainId Chain ID of the asset being added
    /// @param _asset Token address of the assset being added
    /// @param _precision Decimals of precision for the asset being added
    function addSupportedAsset(uint256 _chainId, address _asset, uint8 _precision) external {
        if (msg.sender != admin) revert();
        if (!supportedChains[_chainId]) revert();
        if (supportedAsset[_chainId][_asset] != 0) revert();
        if (_precision == 0) revert();
        supportedAsset[_chainId][_asset] = _precision;
    }

    function proposeFees(uint256 _makerFee, uint256 _takerFee) external override {
        if (msg.sender != admin) revert();
        _proposeFees(_makerFee, _takerFee);
    }

    function updateFees() external override {
        if (msg.sender != admin) revert();
        _updateFees();
    }

    function getReceiverAddress(uint256 _chainId) external view returns (address) {
        return receivers[_chainId];
    }

    function isValidator(address _validator) external view returns (bool) {
        return _validator == validator;
    }

    function isSupportedAsset(uint256 _chainId, address _asset) external view returns (bool) {
        return supportedAsset[_chainId][_asset] > 0;
    }
}
