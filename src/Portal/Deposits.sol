// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../StateUpdateLibrary.sol";

contract Deposits {
    mapping(bytes32 => StateUpdateLibrary.Deposit) public deposits;
}
