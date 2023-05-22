// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/extensions/ERC20Snapshot.sol";

contract CollateralToken is ERC20Snapshot {
    address immutable admin;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        admin = msg.sender;
    }

    // only collateral contract can mint upon stake
    function mint(address _recipient, uint256 _amount) external {
        if (msg.sender != admin) revert();
        _mint(_recipient, _amount);
    }

    // only collateral contract can burn upon unstake

    // get balance for staker

    function snapshot() external returns (uint256) {
        // caller must be collateral contract
        if (msg.sender != admin) revert();
        return _snapshot();
    }
}
