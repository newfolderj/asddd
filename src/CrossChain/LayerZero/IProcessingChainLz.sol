// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../../Portal/IPortal.sol";

interface IProcessingChainLz {
    function sendObligations(
        uint256 _chainId,
        IPortal.Obligation[] calldata _obligations,
        bytes calldata _adapterParams,
        address _refundAddress
    )
        external
        payable;
}
