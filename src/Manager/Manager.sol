// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../Portal/Portal.sol";

abstract contract Manager {
    address public immutable admin;
    address public immutable validator;
    address public immutable participatingInterface;

    constructor(address _participatingInterface, address _admin, address _validator) {
        admin = _admin;
        validator = _validator;
        participatingInterface = _participatingInterface;
    }

}
