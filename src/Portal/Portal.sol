// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../StateUpdateLibrary.sol";
import "../Manager/IManager.sol";
import "../Rollup/IRollup.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

/**
 * The Portal is the entry and exit point for all assets in the TXA network.
 */
contract Portal {
    /**
     * Stores the next ID in the sequence that will be assigned to either a
     * Deposit or SettlementRequest which occurs on this chain.
     */
    uint256 public chainSequenceId = 0;
    uint256 public settlementId = 1;
    address immutable participatingInterface;
    IManager immutable manager;

    mapping(bytes32 => StateUpdateLibrary.Deposit) public deposits;
    mapping(bytes32 => uint256) public balances;
    mapping(bytes32 => bool) public claimed;
    mapping(uint256 => StateUpdateLibrary.SettlementRequest) public settlementRequests;

    event DepositUtxo(
        address wallet,
        uint256 amount,
        address token,
        address participatingInterface,
        uint256 chainSequenceId,
        bytes32 utxo
    );

    error CALLER_NOT_ROLLUP();
    error INSUFFICIENT_BALANCE_TOKEN();
    error INSUFFICIENT_BALANCE_OBLIGATION();
    error INSUFFICIENT_BALANCE_WITHDRAW();
    error TRANSFER_FAILED_WITHDRAW();
    error TOKEN_TRANSFER_FAILED_WITHDRAW();
    error UTXO_ALREADY_CLAIMED();

    // Alpha compatibility
    event Deposit(address wallet, uint256 amount, address token, uint256 chainSequenceId);
    event SettlementRequested(uint256 settlementID, address trader, address token, uint256 chainSequenceId);
    event ObligationWritten(address deliverer, address recipient, address token, uint256 amount);
    event Withdraw(address wallet, uint256 amount, address token);

    mapping(address => mapping(address => uint256)) public availableToWithdraw;

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IManager(_manager);
    }

    //
    // Deposits and Settlement Requests
    //
    // These actions are initiated by traders on-chain and increment the chain
    // sequence ID for this chain and participating interface.
    // The Participating Interface must submit State Updates acknowledging these
    // actions in the same order which they occurred on-chain.
    //

    /**
     * Allows trader to deposit the native asset of this chain.
     *
     * TODO: Handle chains with multiple native assets (e.g. Celo)
     */
    function depositNativeAsset() external payable {
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, address(0), participatingInterface, msg.value, chainSequenceId, block.chainid
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        deposits[utxo] = deposit;
        balances[utxo] = msg.value;
        emit DepositUtxo(msg.sender, msg.value, address(0), participatingInterface, chainSequenceId, utxo);
        // Alpha compatibility
        emit Deposit(msg.sender, msg.value, address(0), chainSequenceId);
        chainSequenceId++;
    }

    /**
     * Allows trader to deposit an ERC20 token.
     */
    function depositToken(address _token, uint256 _amount) external {
        // TODO: check if token is tradable
        if (!IERC20(_token).transferFrom(msg.sender, address(this), _amount)) revert INSUFFICIENT_BALANCE_TOKEN();
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, _token, participatingInterface, _amount, chainSequenceId, block.chainid
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        deposits[utxo] = deposit;
        balances[utxo] = _amount;
        emit DepositUtxo(msg.sender, _amount, _token, participatingInterface, chainSequenceId, utxo);
        // Alpha compatibility
        emit Deposit(msg.sender, _amount, _token, chainSequenceId);
        chainSequenceId++;
    }

    function requestSettlement(address _token) external {
        // TODO: check if token is tradable
        uint256 id = IRollup(manager.rollup()).requestSettlement(_token, msg.sender);
        settlementRequests[chainSequenceId] = StateUpdateLibrary.SettlementRequest(
            msg.sender, _token, participatingInterface, chainSequenceId, block.chainid, id
        );
        emit SettlementRequested(id, msg.sender, _token, chainSequenceId);
        chainSequenceId++;
    }

    function writeObligation(bytes32 _utxo, bytes32 _deposit, address _recipient, uint256 _amount) external {
        if (msg.sender != manager.rollup()) revert CALLER_NOT_ROLLUP();

        if (balances[_deposit] < _amount) revert INSUFFICIENT_BALANCE_OBLIGATION();

        if (claimed[_utxo]) revert UTXO_ALREADY_CLAIMED();

        address token = deposits[_deposit].asset;
        availableToWithdraw[_recipient][token] += _amount;
        unchecked {
            balances[_deposit] -= _amount;
        }
        emit ObligationWritten(deposits[_deposit].trader, _recipient, token, _amount);
    }

    function getAvailableBalance(address _trader, address _token) external view returns (uint256) {
        return availableToWithdraw[_trader][_token];
    }

    function withdraw(uint256 _amount, address _token) external {
        if (availableToWithdraw[msg.sender][_token] < _amount) revert INSUFFICIENT_BALANCE_WITHDRAW();

        unchecked {
            availableToWithdraw[msg.sender][_token] -= _amount;
        }

        if (_token == address(0)) {
            (bool success,) = msg.sender.call{value: _amount}("");
            if (!success) revert TRANSFER_FAILED_WITHDRAW();
        } else {
            if (!IERC20(_token).transfer(msg.sender, _amount)) revert TOKEN_TRANSFER_FAILED_WITHDRAW();
        }
        emit Withdraw(msg.sender, _amount, _token);
    }
}
