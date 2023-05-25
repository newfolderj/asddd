// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "@openzeppelin/utils/math/Math.sol";

abstract contract FeeManager {
    uint256 public constant BASE = 10;
    uint256 public constant DENOMINATOR = 10**BASE;
    uint256 public constant ONE_PERCENT_NUMERATOR = 10**(BASE - 2);     // 1.00%
    uint256 public constant ONE_BPS_NUMERATOR = 10**(BASE - 4);         // 0.01%

    uint256 public constant MAX_FEE_NUMERATOR = 5 * (10**(BASE - 3));   // 0.50%
    uint256 public constant MIN_FEE_NUMERATOR = ONE_BPS_NUMERATOR;      // 0.01%
    uint256 makerFee = 5 * ONE_BPS_NUMERATOR;
    uint256 takerFee = 5 * ONE_BPS_NUMERATOR;

    // Determines which percentage of fees go to the settlement layer.
    // Remaining goes to the participating interface.
    uint256 protocolFee = 50 * ONE_PERCENT_NUMERATOR;

    // Determines how much of settlement fee goes to the insurance fund.
    uint256 insuranceFundFee = 50 * ONE_PERCENT_NUMERATOR;

    event UpdateMakerFee();
    event UpdateTakerFee();

    function setMakerFee(uint256 _makerFee) external virtual;
    function setTakerFee(uint256 _takerFee) external virtual;

    modifier withinFeeLimits(uint256 _fee) {
        if(_fee > MAX_FEE_NUMERATOR) revert();
        if(_fee < MIN_FEE_NUMERATOR) revert();
        _;
    }

    function _setMakerFee(uint256 _makerFee) withinFeeLimits(_makerFee) internal {
        makerFee = _makerFee;
        // TODO: get and bump chain sequence ID
        emit UpdateMakerFee();
    }

    function _setTakerFee(uint256 _takerFee) withinFeeLimits(_takerFee) internal {
        takerFee = _takerFee;
        // TODO: get and bump chain sequence ID
        emit UpdateTakerFee();
    }
}
