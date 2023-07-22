// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IBaseManager {
    function fraudPeriod() external view returns (uint256);
    function collateral() external view returns (address);
    function rollup() external view returns (address);
    function relayer() external view returns (address);
    function fraudEngine() external view returns (address);
    function walletDelegation() external view returns (address);
    function oracle() external view returns (address);
    function supportedAsset(uint256 chainId, address asset) external view returns (uint8);
    function getReceiverAddress(uint256 _chainId) external view returns (address);
    function isValidator(address validator) external view returns (bool);
    function isSupportedAsset(uint256 chainId, address asset) external view returns (bool);
}
