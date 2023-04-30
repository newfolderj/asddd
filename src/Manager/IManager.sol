// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IManager {
    function portal() external view returns (address);
    function rollup() external view returns (address);
    function isValidator(address validator) external view returns (bool);
}
