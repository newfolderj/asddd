// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../Rollup/Rollup.sol";
import "../Portal/Portal.sol";
import "./IManager.sol";

contract Manager is IManager {
    address public immutable admin;
    address public immutable validator;
    address public immutable portal;
    address public immutable rollup;

    constructor(address _participatingInterface, address _admin, address _validator)  {
        portal = address(new Portal(_participatingInterface, address(this)));
        rollup = address(new Rollup(_participatingInterface, address(this)));
        admin = _admin;
        validator = _validator;
    }

    function isValidator(address _validator) external view returns(bool) {
        return _validator == validator;
    }
}
