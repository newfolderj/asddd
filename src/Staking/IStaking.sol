// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

interface IStaking {
    function lock(address _asset, uint256 _amountToLock) external returns (uint256);
    function reward(uint256 _lockId, uint256 _chainId, address _asset, uint256 _amount) external;
    function payInsurance(uint256 _chainId, address _asset, uint256 _amount) external;
    function stablecoin() external view returns (address);
    function protocolToken() external view returns (address);
    function getAvailableCollateral(address _asset) external view returns (uint256);
}
