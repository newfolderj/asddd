// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IOracle.sol";
import "../Manager/ProcessingChain/IProcessingChainManager.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Oracle
/// @author Arseniy Klempner
/// @notice Allows authorized reporters to submit prices for supported assets denominated in the protocol's chosen
/// stablecoin.
/// Whether the reporter is a contract or an EOA, it is expected to report prices in 18 decimals of precision.
/// e.g. If 1 ETH costs 1800 units of a whole stablecoin, the reporter should submit a price of 1800e18
contract Oracle is IOracle {
    /// @notice Stores price of asset in stablecoin. Uses 18 decimals of precision
    /// Maps chain ID to asset address to latest price.
    mapping(uint256 => mapping(address => uint256)) public latestPrice;
    /// @notice Stores last block number at which a price was reported for an asset.
    /// Maps chain ID to asset address to last block number at which a price was reported
    mapping(uint256 => mapping(address => uint256)) public lastReport;
    /// @notice Stores number of decimals of precision for an asset.
    /// Maps chain ID to asset address to decimals of precision
    mapping(uint256 => mapping(address => uint8)) public tokenPrecision;

    /// Number of blocks after which a price is considered expired and can no longer be used.
    uint256 public constant PRICE_EXPIRY = 1800; // About 6 hours on Ethereum
    /// Number of blocks that must pass before price can be updated again
    uint256 public constant PRICE_COOLDOWN = 75; // About 15 minutes on Ethereum

    address public admin;
    address public manager;
    mapping(address => bool) public isReporter;

    address immutable protocolToken;
    address immutable stablecoinAssetChain;
    uint256 immutable stablecoinAssetChainId;

    constructor(
        address _admin,
        address _manager,
        address _protocolToken,
        address _stablecoinAssetChain,
        uint256 _stablecoinAssetChainId,
        uint256 _protocolTokenPrice
    ) {
        admin = _admin;
        manager = _manager;
        protocolToken = _protocolToken;
        stablecoinAssetChain = _stablecoinAssetChain;
        stablecoinAssetChainId = _stablecoinAssetChainId;

        tokenPrecision[block.chainid][_protocolToken] = IERC20Metadata(protocolToken).decimals();
        lastReport[block.chainid][_protocolToken] = block.number;
        latestPrice[block.chainid][_protocolToken] = _protocolTokenPrice;
    }

    /// Called by the admin to authorized an address as a reporter
    /// @param _reporter Address being authorized to report prices
    function grantReporter(address _reporter) external {
        if (msg.sender != admin) revert("Only admin");
        isReporter[_reporter] = true;
    }

    /// Called by the admin to un-authorize an address as a reporter
    /// @param _reporter Address being unauthorized from reporting prices
    function revokeReporter(address _reporter) external {
        if (msg.sender != admin) revert("Only admin");
        isReporter[_reporter] = false;
    }

    /// Called by address authorized as the reporter to submit the first price for an asset.
    /// Also registers the decimals of precision for the asset.
    /// @param _chainId Chain ID of the asset
    /// @param _asset  Token address of the asset (address(0) if it's the native asset)
    /// @param _price  Price of the asset in stablecoin. Uses 18 decimals of precision
    function initializePrice(uint256 _chainId, address _asset, uint256 _price) external {
        if (!isReporter[msg.sender]) revert("Only reporter");
        uint8 precision = IProcessingChainManager(manager).supportedAsset(_chainId, _asset);
        if (precision == 0) revert("Unsupported asset");
        uint256 lastPrice = latestPrice[_chainId][_asset];
        if (lastPrice > 0) revert("Already initialized");
        tokenPrecision[_chainId][_asset] = precision;
        lastReport[_chainId][_asset] = block.number;
        latestPrice[_chainId][_asset] = _price;
    }

    /// Called by address authorized as the reporter to submit a new price for an asset.
    /// Price cannot change by more than 15% each time the function is called.
    /// Price cannot change more than once within every `PRICE_COOLDOWN` range of blocks.
    /// @param _chainId Chain ID of the asset
    /// @param _asset  Token address of the asset
    /// @param _price  Updated price of the asset
    /// @param _modulo Flag indicating to use max/min amount if price is out of those bounds.
    function report(uint256 _chainId, address _asset, uint256 _price, bool _modulo) external {
        if (!isReporter[msg.sender]) revert("Only reporter");
        if (block.number < lastReport[_chainId][_asset] + PRICE_COOLDOWN) {
            revert("Price cooldown period has not passed");
        }
        uint256 lastPrice = latestPrice[_chainId][_asset];
        uint256 min = (lastPrice * 0.85e18) / 1e18;
        uint256 max = (lastPrice * 1.15e18) / 1e18;
        if (_modulo && _price > max) _price = max;
        if (_modulo && _price < min) _price = min;
        if (_price > max || _price < min) {
            revert("Reject price changes of more than 15%");
        }
        lastReport[_chainId][_asset] = block.number;
        latestPrice[_chainId][_asset] = _price;
    }

    /// Given a `_chainId` and address of an `_asset`, along with an `_amount`, calculates
    /// the equivalent value in the protocol's stablecoin asset.
    /// Reverts if too much time has passed since the last price for this asset was reported.
    /// @param _chainId Chain ID of the asset being converted
    /// @param _asset Token address of the asset being converted (`address(0)` if it's a native asset)
    /// @param _amount Amount of the asset, in the asset's native precision, being converted
    function getStablecoinValue(uint256 _chainId, address _asset, uint256 _amount) external view returns (uint256) {
        // If the asset being settled is the stablecoin on its asset chain, then just return the amount.
        // This assumes the bridged stablecoin on the processing chain has the same number of digits of precision.
        if (_chainId == stablecoinAssetChainId && _asset == stablecoinAssetChain) return _amount;
        if (block.number >= lastReport[_chainId][_asset] + PRICE_EXPIRY) revert("Price for asset has expired");
        uint256 price = latestPrice[_chainId][_asset];
        uint256 precision = tokenPrecision[_chainId][_asset];
        uint256 value = (_amount * price) / 1e18;
        if (precision > 6) {
            return value / (10 ** (precision - 6));
        } else if (precision < 6) {
            return value * (10 ** (6 - precision));
        } else {
            return value;
        }
    }

    /// Converts a given `_amount` of stablecoin to equivalent amount of protocol token.
    /// Assumes stablecoin token uses 6 decimals of precision and protocol token uses 18.
    /// @param _amount Amount of stablecoin to convert to protocol token
    function stablecoinToProtocol(uint256 _amount) external view returns (uint256) {
        if (block.number >= lastReport[block.chainid][protocolToken] + PRICE_EXPIRY) {
            revert("Price for asset has expired");
        }
        uint256 price = latestPrice[block.chainid][protocolToken];
        return ((_amount * (10 ** 18)) / price) * (10 ** 12);
    }
}
