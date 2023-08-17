// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint8 precision;

    constructor(
        address[] memory airdrop,
        string memory name,
        string memory symbol,
        uint8 _precision
    ) ERC20(name, symbol) {
        if(_precision < 6 ) revert("Insufficient precision");
        precision = _precision;
        for (uint256 i = 0; i < airdrop.length; i++) {
            _mint(airdrop[i], 100_000e18);
        }
    }

    function decimals() public view override returns (uint8) {
        return precision;
    }
}
