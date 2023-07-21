// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./IPortal.sol";
import "./Deposits.sol";
import "../StateUpdateLibrary.sol";
import "../Manager/IBaseManager.sol";
import "../Manager/IChildManager.sol";
import "../Rollup/IRollup.sol";
import "../util/Id.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * The Portal is the entry and exit point for all assets in the TXA network.
 */
contract Portal is IPortal, Deposits {
    using IdLib for Id;

    /**
     * Stores the next ID in the sequence that will be assigned to either a
     * Deposit or SettlementRequest which occurs on this chain.
     */
    Id public chainSequenceId = ID_ZERO;
    Id public nextRequestId = Id.wrap(2);
    address immutable participatingInterface;
    IBaseManager immutable manager;

    mapping(bytes32 => bool) public claimed;
    mapping(Id => StateUpdateLibrary.SettlementRequest) public settlementRequests;

    event DepositUtxo(
        address wallet, uint256 amount, address token, address participatingInterface, Id chainSequenceId, bytes32 utxo
    );

    error CALLER_NOT_ROLLUP();
    error INSUFFICIENT_BALANCE_TOKEN();
    error INSUFFICIENT_BALANCE_OBLIGATION(address _token, uint256 available, uint256 obligation);
    error INSUFFICIENT_BALANCE_WITHDRAW();
    error TRANSFER_FAILED_WITHDRAW();
    error TOKEN_TRANSFER_FAILED_WITHDRAW();
    error UTXO_ALREADY_CLAIMED();

    // Alpha compatibility
    event Deposit(address wallet, uint256 amount, address token, Id chainSequenceId);
    event SettlementRequested(uint256 settlementID, address trader, address token, Id chainSequenceId);
    event ObligationWritten(address deliverer, address recipient, address token, uint256 amount);
    event Withdraw(address wallet, uint256 amount, address token);

    mapping(address => uint256) public collateralized;
    mapping(address => mapping(address => uint256)) public settled;

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IBaseManager(_manager);
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
        if (msg.value % 1e12 != 0) revert("Invalid amount");
        uint256 value = msg.value / 1e12;
        if (value >= type(uint64).max) revert("Amount is too large");
        if (value == 0) revert("Invalid amount");
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, address(0), participatingInterface, uint64(value), chainSequenceId, Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        deposits[utxo] = deposit;
        unchecked {
            collateralized[address(0)] += msg.value;
        }
        emit DepositUtxo(msg.sender, msg.value, address(0), participatingInterface, chainSequenceId, utxo);
        // Alpha compatibility
        emit Deposit(msg.sender, msg.value, address(0), chainSequenceId);
        chainSequenceId = chainSequenceId.increment();
    }

    /**
     * Allows trader to deposit an ERC20 token.
     */
    function depositToken(address _token, uint256 _amount) external {
        // TODO: check if token is tradable
        // get precision
        uint256 precision = IERC20Metadata(_token).decimals();
        uint256 value = _amount;
        if (precision > 6) {
            precision = precision - 6;
            if (_amount % (10 ** precision) != 0) revert("Invalid precision");
            value = _amount / (10 ** precision);
            if (value == 0) revert("Amount is below minimum deposit");
        }
        if (value >= type(uint64).max) revert("Amount is above maximum deposit");

        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, _token, participatingInterface, uint64(value), chainSequenceId, Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        deposits[utxo] = deposit;
        unchecked {
            collateralized[_token] += _amount;
        }
        if (!IERC20(_token).transferFrom(msg.sender, address(this), _amount)) revert INSUFFICIENT_BALANCE_TOKEN();
        emit DepositUtxo(msg.sender, _amount, _token, participatingInterface, chainSequenceId, utxo);
        // Alpha compatibility
        emit Deposit(msg.sender, _amount, _token, chainSequenceId);
        chainSequenceId = chainSequenceId.increment();
    }

    function requestSettlement(address _token) external {
        // TODO: check if token is tradable
        settlementRequests[chainSequenceId] = StateUpdateLibrary.SettlementRequest(
            msg.sender, _token, participatingInterface, chainSequenceId, Id.wrap(block.chainid), nextRequestId
        );
        emit SettlementRequested(Id.unwrap(nextRequestId), msg.sender, _token, chainSequenceId);
        chainSequenceId = chainSequenceId.increment();
        nextRequestId = nextRequestId.increment();
    }

    function writeObligations(Obligation[] calldata obligations) external {
        if (msg.sender != IChildManager(address(manager)).receiver()) revert("Only receiver can write obligations");
        for (uint256 i = 0; i < obligations.length; i++) {
            uint256 amount = obligations[i].amount;
            uint256 precision;
            if (obligations[i].asset == address(0)) {
                precision = 18;
            } else {
                precision = IERC20Metadata(obligations[i].asset).decimals();
            }
            if (precision > 6) {
                precision = precision - 6;
                amount = obligations[i].amount * (10 ** precision);
            }
            if (collateralized[obligations[i].asset] < amount) revert INSUFFICIENT_BALANCE_OBLIGATION(obligations[i].asset, collateralized[obligations[i].asset], amount);

            collateralized[obligations[i].asset] -= amount;
            settled[obligations[i].recipient][obligations[i].asset] += amount;
        }
    }

    function withdraw(uint256 _amount, address _token) external {
        if (settled[msg.sender][_token] < _amount) revert INSUFFICIENT_BALANCE_WITHDRAW();

        unchecked {
            settled[msg.sender][_token] -= _amount;
        }

        if (_token == address(0)) {
            (bool success,) = msg.sender.call{ value: _amount }("");
            if (!success) revert TRANSFER_FAILED_WITHDRAW();
        } else {
            if (!IERC20(_token).transfer(msg.sender, _amount)) revert TOKEN_TRANSFER_FAILED_WITHDRAW();
        }
        emit Withdraw(msg.sender, _amount, _token);
    }

    // Called by other contracts to assign a chain sequence number to an event
    function sequenceEvent() external returns (uint256 _chainSequenceId) {
        // Can only be called by WalletDelegation and FeeManager
        // On a child chain, this call should fail
        if (!(msg.sender == IBaseManager(address(manager)).walletDelegation() || msg.sender == address(manager))) {
            revert();
        }
        // Return current ID before incrementing
        _chainSequenceId = Id.unwrap(chainSequenceId);
        chainSequenceId = chainSequenceId.increment();
    }

    function getAvailableBalance(address _trader, address _token) external view returns (uint256) {
        return settled[_trader][_token];
    }

    function isValidSettlementRequest(uint256 _chainSequenceId, bytes32 _settlementHash) external view returns (bool) {
        return keccak256(abi.encode(settlementRequests[Id.wrap(_chainSequenceId)])) == _settlementHash;
    }

    function convertPrecision(uint256 _amount, address _token) public view returns (uint64) {
        uint256 precision = _token == address(0) ? 18 : IERC20Metadata(_token).decimals();
        uint256 value = _amount;
        if (precision > 6) {
            precision = precision - 6;
            if (_amount % (10 ** precision) != 0) revert("Invalid precision");
            value = _amount / (10 ** precision);
            if (value == 0) revert("Amount is below minimum deposit");
        }
        if (value >= type(uint64).max) revert("Amount is above maximum deposit");
        return uint64(value);
    }
}
