// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IOracle {
    function getPrice(address _base, address _counter) external returns (uint256);
}
