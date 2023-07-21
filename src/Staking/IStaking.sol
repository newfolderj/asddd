// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

interface IStaking {
    function lock(address _asset, uint256 _amountToLock) external returns (uint256);
    function reward(uint256 _lockId, uint256 _chainId, address _asset, uint64 _amount) external;
    function payInsurance(uint256 _chainId, address _asset, uint64 _amount) external;
    function stablecoin() external view returns (address);
    function protocolToken() external view returns (address);
    function ROOT_PROPOSAL_LOCK_AMOUNT() external view returns (uint256);
    function stablecoinToProtocol(uint256 _stablecoinAmount) external pure returns (uint256);
}
