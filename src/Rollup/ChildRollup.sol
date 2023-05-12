// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./Rollup.sol";
import "./IChildRollup.sol";
import "../Portal/IPortal.sol";
import "../Manager/IManager.sol";
import "../StateUpdateLibrary.sol";
import "../util/Id.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * The Rollup contract accepts settlement data reports from validators.
 */
contract ChildRollup is Rollup, IChildRollup {
    using IdLib for Id;

    constructor(address _participatingInterface, address _manager) Rollup(_participatingInterface, _manager) { }

    function receiveStateRoot(bytes32 _stateRoot) external {
        confirmedStateRoot[epoch] = _stateRoot;
        epoch = epoch.increment();
    }
}
