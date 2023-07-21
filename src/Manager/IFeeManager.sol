// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IFeeManager {
    function calculateInsuranceFee(uint256 amount) external view returns(uint256);
    function calculateSettlementFees(uint256 settlementAmount) external view returns(uint64 insuranceFee, uint64 stakerReward);
    function calculateStakingRewards(uint256 stakingReward) external view returns (uint64 stablePoolReward, uint64 protocolPoolReward);
}
