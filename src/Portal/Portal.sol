// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;
import "./IPortal.sol";
import "./Deposits.sol";
import "../StateUpdateLibrary.sol";
import "../Manager/IChildManager.sol";
import "../Manager/IChildManager.sol";
import "../Rollup/IRollup.sol";
import "../util/Id.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    IChildManager immutable manager;

    mapping(bytes32 => bool) public claimed;
    mapping(Id => StateUpdateLibrary.SettlementRequest) public settlementRequests;

    event DepositUtxo(
        address wallet, uint256 amount, address token, address participatingInterface, Id chainSequenceId, bytes32 utxo
    );

    error CALLER_NOT_ROLLUP();
    error INSUFFICIENT_BALANCE_TOKEN();
    error INSUFFICIENT_BALANCE_OBLIGATION();
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
        manager = IChildManager(_manager);
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
     */
    function depositNativeAsset() external payable {
        if(!manager.supportedAsset(address(0))) revert("Native asset is not supported");
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, address(0), participatingInterface, msg.value, chainSequenceId, Id.wrap(block.chainid)
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
        if(!manager.supportedAsset(_token)) revert("Asset is not supported");
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, _token, participatingInterface, _amount, chainSequenceId, Id.wrap(block.chainid)
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
        if(!manager.supportedAsset(_token)) revert("Asset is not supported");
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
            if (collateralized[obligations[i].asset] < obligations[i].amount) revert INSUFFICIENT_BALANCE_OBLIGATION();

            collateralized[obligations[i].asset] -= obligations[i].amount;
            settled[obligations[i].recipient][obligations[i].asset] += obligations[i].amount;
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
    // function sequenceEvent() external returns (uint256 _chainSequenceId) {
    //     // Can only be called by WalletDelegation and FeeManager
    //     // On a child chain, this call should fail
    //     if (!(msg.sender == IChildManager(address(manager)).walletDelegation() || msg.sender == address(manager))) {
    //         revert();
    //     }
    //     // Return current ID before incrementing
    //     _chainSequenceId = Id.unwrap(chainSequenceId);
    //     chainSequenceId = chainSequenceId.increment();
    // }

    function getAvailableBalance(address _trader, address _token) external view returns (uint256) {
        return settled[_trader][_token];
    }

    function isValidSettlementRequest(uint256 _chainSequenceId, bytes32 _settlementHash) external view returns (bool) {
        return keccak256(abi.encode(settlementRequests[Id.wrap(_chainSequenceId)])) == _settlementHash;
    }
}
