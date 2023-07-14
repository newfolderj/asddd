// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "./util/Id.sol";

library StateUpdateLibrary {
    uint8 public constant TYPE_ID_DepositAcknowledgement = 0x00;
    uint8 public constant TYPE_ID_Trade = 0x01;
    uint8 public constant TYPE_ID_Settlement = 0x02;
    uint8 public constant TYPE_ID_FeeUpdate = 0x03;
    uint8 public constant TYPE_ID_DepositRejection = 0x04;
    // uint8 public constant TYPE_ID_InitializeSettings = 0x03;
    // uint8 public constant TYPE_ID_Ping = 0x04;
    // uint8 public constant TYPE_ID_NewProduct = 0x05;

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct StateUpdate {
        uint8 typeIdentifier;
        Id sequenceId;
        address participatingInterface;
        bytes structData;
    }

    struct SignedStateUpdate {
        StateUpdate stateUpdate;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * The structData field in StateUpdate deserializes to one of the following structs:
     * 1. InitializeSettings
     * 2. DepositAcknowledgement
     * 3. Trade
     * 4. SettlementAcknowledgement
     * 5. FeeUpdate
     * 6. DelegationAcknowledgement
     */
    struct InitializeSettings {
        address tradeSigningKey;
        address feeRecipient;
        uint256 settlementFeeNumerator;
        uint256 interfaceFeeNumerator;
        uint256 feeDenominator;
    }

    struct FeeUpdate {
        uint256 feeSequenceId;
        uint256 newMakerFee;
        uint256 newTakerFee;
        // State Update ID which has the FeeUpdate with feeSquenceId - 1
        uint256 lastFeeUpdate;
    }

    struct DepositAcknowledgement {
        Deposit deposit;
        Id balanceBeforeId;
        Balance balanceBefore;
        Balance balanceAfter;
        Id depositRootBeforeId;
        bytes32 depositRootBefore;
        bytes32 depositRootAfter;
    }

    struct DepositRejection {
        Deposit deposit;
        Id depositRootBeforeId;
        bytes32 depositRootBefore;
        bytes32 depositRootAfter;
    }

    struct Balance {
        address trader;
        address asset;
        Id chainId;
        uint256 amount;
    }

    struct Trade {
        Id feeUpdateId; // Sequence ID of FeeUpdate canonical to this trade
        TradeParams params;
        Id makerBaseBalanceBeforeId;
        Balance makerBaseBalanceBefore;
        Id makerCounterBalanceBeforeId;
        Balance makerCounterBalanceBefore;
        Id takerBaseBalanceBeforeId;
        Balance takerBaseBalanceBefore;
        Id takerCounterBalanceBeforeId;
        Balance takerCounterBalanceBefore;
        Balance makerBaseBalanceAfter;
        Balance makerCounterBalanceAfter;
        Balance takerBaseBalanceAfter;
        Balance takerCounterBalanceAfter;
        Balance makerFee;
        Balance takerFee;
    }

    struct Settlement {
        SettlementRequest settlementRequest;
        Id balanceBeforeId;
        Balance balanceBefore;
        Balance balanceAfter;
    }

    struct UTXO {
        address trader;
        uint256 amount;
        uint256 stateUpdateId;
        bytes32 parentUtxo;
        bytes32 depositUtxo;
        address participatingInterface;
        address asset;
        Id chainId;
    }

    struct NewProduct {
        address assetA;
        uint256 chainIdA;
        address assetB;
        uint256 chainIdB;
        uint64 exchangePrecisionA;
        uint64 exchangePrecisionB;
        uint64 nativePrecisionA;
        uint64 nativePrecisionB;
    }

    struct Deposit {
        address trader;
        address asset;
        address participatingInterface;
        uint256 amount;
        Id chainSequenceId;
        Id chainId;
    }

    struct SettlementRequest {
        address trader;
        address asset;
        address participatingInterface;
        Id chainSequenceId;
        Id chainId;
        Id settlementId;
    }

    struct TradeParams {
        address participatingInterface;
        SignedOrder orderA;
        SignedOrder orderB;
        Product product;
        uint256 size;
        uint256 price;
        address maker;
        address taker;
    }

    struct Product {
        address baseAsset;
        uint256 baseAssetChainId;
        address counterAsset;
        uint256 counterAssetChainId;
    }

    struct SignedOrder {
        Order order;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order {
        Product product;
        bool side;
        uint256 size;
        uint256 price;
    }

    struct LimitOrder {
        OrderType orderType;
        Side side;
        uint256 size;
        uint256 total;
        FillType fillType;
        uint256 price;
        Signature sig;
    }

    enum Side {
        ORDER_SIDE_BUY,
        ORDER_SIDE_SELL
    }

    enum OrderType {
        ORDER_TYPE_CONTINGENT,
        ORDER_TYPE_LMT,
        ORDER_TYPE_MKT,
        ORDER_TYPE_MULTI_CONTINGENT,
        ORDER_TYPE_NONE,
        ORDER_TYPE_OCO,
        ORDER_TYPE_OTO,
        ORDER_TYPE_OTOCO,
        ORDER_TYPE_STOP,
        ORDER_TYPE_STOP_LMT,
        ORDER_TYPE_TRAILING_STOP,
        ORDER_TYPE_TRAILING_STOP_LMT
    }

    enum FillType {
        ORDER_FILL_TYPE_AON,
        ORDER_FILL_TYPE_FOK,
        ORDER_FILL_TYPE_NORM
    }

    struct Asset {
        uint64 assetId;
        uint64 networkType;
        uint64 chainId;
        uint64 extra;
    }
}
