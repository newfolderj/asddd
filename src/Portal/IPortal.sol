// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IPortal {
    function writeObligation(address token, address recipient, uint256 amount) external;

    function sequenceEvent() external returns (uint256);

    function getAvailableBalance(address trader, address token) external view returns (uint256);

    function isValidSettlementRequest(uint256 chainSequenceId, bytes32 settlementHash) external view returns (bool);
}
