// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IChildManager {
    function relayer() external view returns (address);
    function portal() external view returns (address);
    function receiver() external view returns (address);
}
