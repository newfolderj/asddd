// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./ICollateral.sol";
import "./CollateralToken.sol";
import "../StateUpdateLibrary.sol";
import "../Manager/IManager.sol";
import "../Rollup/IRollup.sol";
import "../Oracle/IOracle.sol";
import "../util/Id.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

/**
 * The Portal is the entry and exit point for all assets in the TXA network.
 */
contract Collateral is ICollateral {
    using IdLib for Id;

    /**
     * Stores the next ID in the sequence that will be assigned to either a
     * Deposit or SettlementRequest which occurs on this chain.
     */
    Id public chainSequenceId = ID_ZERO;
    address immutable participatingInterface;
    IManager immutable manager;

    // Epoch ID to Asset to Amount Received in fees
    mapping(Id => mapping(address => uint256)) public fees;
    // Epoch ID to Asset to Snapshot ID of corresponding Collateral token
    mapping(Id => mapping(address => uint256)) public snapshotId;
    // For an individual staker, amount of fees claimed for an epoch
    mapping(address => mapping(Id => mapping(address => uint256))) public feesClaimed;

    mapping(address => uint256) total;
    // mapping(address => uint256) available;
    mapping(address => uint256) locked;

    address immutable stablecoin;
    address immutable protocolToken;

    CollateralToken stablecoinCollateral;
    CollateralToken protocolCollateral;

    error CALLER_NOT_ROLLUP(address sender, address expected);

    // Amount of protocol token necessary to stake to propose a state root
    uint256 public constant PROTOCOL_STAKE_AMOUNT = 10_000;

    constructor(address _participatingInterface, address _manager, address _stablecoin, address _protocolToken) {
        participatingInterface = _participatingInterface;
        manager = IManager(_manager);
        stablecoin = _stablecoin;
        protocolToken = _protocolToken;
        stablecoinCollateral = new CollateralToken("StablecoinCollateral", "TXASC");
        protocolCollateral = new CollateralToken("ProtocolCollateral", "TXAPC");
    }

    // called by rollup contract when state root is proposed
    function lockForStateRootProposal() external {
        if (msg.sender != manager.rollup()) revert CALLER_NOT_ROLLUP(msg.sender, manager.rollup());
        if (locked[protocolToken] + PROTOCOL_STAKE_AMOUNT > total[protocolToken]) revert();
        unchecked {
            locked[protocolToken] += PROTOCOL_STAKE_AMOUNT;
        }
    }

    // called by rollup contract when state root is proposed
    function lockForReport(uint256 _epoch, uint256 _stablecoin, uint256 _protocol) external {
        if (msg.sender != manager.rollup()) revert CALLER_NOT_ROLLUP(msg.sender, manager.rollup());
        if (locked[address(stablecoinCollateral)] + _stablecoin > total[address(stablecoinCollateral)]) revert();
        if (locked[address(protocolCollateral)] + _protocol > total[address(protocolCollateral)]) revert();
        unchecked {
            locked[address(stablecoinCollateral)] += _stablecoin;
            locked[address(protocolCollateral)] += _protocol;
        }

        // take snapshot of each token
        snapshotId[Id.wrap(_epoch)][address(stablecoinCollateral)] = stablecoinCollateral.snapshot();
        snapshotId[Id.wrap(_epoch)][address(protocolCollateral)] = protocolCollateral.snapshot();
    }

    function receiveFee(Id _epoch, address _asset, uint256 _amount) external {
        // only callable by rollup (?)
        fees[_epoch][_asset] += _amount;
    }

    function stake(uint256 _stablecoinAmount) external {
        // get rate of stablecoin token to protocol token from price oracle
        uint256 rate = IOracle(address(manager)).getPrice(address(stablecoin), address(protocolToken));
        // convert stablecoin amount to protocol token amount
        uint256 protocolAmount = _stablecoinAmount * rate;
        // TODO: parameterize the two rates below
        uint256 protocolStake = (protocolAmount * 15e5) / 100e5; // ~15% of stablecoin as protocol token
        // uint256 burnAmount = (protocolStake * 5e4) / 100e5; // ~0.5 % of protocol token is burnt

        _stake(stablecoin, _stablecoinAmount);
        _stake(protocolToken, protocolStake);
        // _burn(protocolToken, burnAmount);
    }

    // Stakes an asset into either the stablecoin or protocol token pool
    function _stake(address _asset, uint256 _amount) internal {
        CollateralToken collateralToken;
        if (_asset == stablecoin) {
            collateralToken = stablecoinCollateral;
        } else if (_asset == protocolToken) {
            collateralToken = protocolCollateral;
        } else {
            revert();
        }
        // transfer from sender to this contract
        require(IERC20(_asset).transferFrom(msg.sender, address(this), _amount));
        // add to total deposits for asset
        total[_asset] += _amount;
        // mint collateral token for sender
        collateralToken.mint(msg.sender, _amount);
    }

    function withdraw(address _asset, uint256 _amount) external {
        // burn collateral token
        // receive proportionate share of collateral
    }

    // After a fee has been processed, any staker with collateral tokens at
    // the snapshot associated with the proposal can withdraw their share.
    function claimFee(Id _epoch, address _asset, uint256 _amount) external {
        uint256 claimed = feesClaimed[msg.sender][_epoch][_asset];
        uint256 totalStablecoinShare = (fees[_epoch][_asset] * 85e4) / 100e4;
        uint256 totalProtocolShare = fees[_epoch][_asset] - totalStablecoinShare;

        uint256 stablecoinSnapshot = snapshotId[_epoch][address(stablecoinCollateral)];
        uint256 stablecoinShare = (
            totalStablecoinShare * stablecoinCollateral.balanceOfAt(msg.sender, stablecoinSnapshot)
        ) / stablecoinCollateral.totalSupplyAt(stablecoinSnapshot);

        uint256 protocolSnapshot = snapshotId[_epoch][address(protocolCollateral)];
        uint256 protocolShare = (totalProtocolShare * protocolCollateral.balanceOfAt(msg.sender, protocolSnapshot))
            / protocolCollateral.totalSupplyAt(protocolSnapshot);

        uint256 availableToWithdraw = (stablecoinShare + protocolShare) - claimed;
        if (_amount > availableToWithdraw) revert();

        feesClaimed[msg.sender][_epoch][_asset] += _amount;

        // transfer fee to msg.sender
        // if the fee token is on this chain, it can just be transferred
        // if the fee token is on a child chain, the message to allocate the fee amount needs to be relayed
        // For now, assume fee asset exists on this chain
        require(IERC20(_asset).transfer(msg.sender, _amount));
    }
}
