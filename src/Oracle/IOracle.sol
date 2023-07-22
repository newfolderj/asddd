// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IOracle {
    function getStablecoinValue(uint256 _chainId, address _asset, uint256 _amount) external returns (uint256);
    function stablecoinToProtocol(uint256 _amount) external view returns (uint256);
}
