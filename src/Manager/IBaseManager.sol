// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IBaseManager {
    function collateral() external view returns (address);
    function fraudEngine() external view returns (address);
    function getReceiverAddress(uint256 _chainId) external view returns (address);
}
