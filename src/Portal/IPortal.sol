// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IPortal {
    function writeObligation(
        bytes32 deposit,
        address recipient,
        uint256 amount
    ) external;

    function getAvailableBalance(
        address trader,
        address token
    ) external view returns (uint256);
}
