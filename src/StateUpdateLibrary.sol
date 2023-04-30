// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

library StateUpdateLibrary {
    uint8 public constant TYPE_ID_DepositAcknowledgement = 0x00;
    uint8 public constant TYPE_ID_Trade = 0x01;
    uint8 public constant TYPE_ID_SettlementAcknowledgement = 0x02;
    uint8 public constant TYPE_ID_InitializeSettings = 0x03;
    uint8 public constant TYPE_ID_Ping = 0x04;
    uint8 public constant TYPE_ID_NewProduct = 0x05;

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct StateUpdate {
        uint8 typeIdentifier;
        uint256 sequenceId;
        address participatingInterface;
        bytes structData;
    }

    struct SignedStateUpdate {
        StateUpdate stateUpdate;
        Signature sig;
    }

    /**
     * The structData field in StateUpdate deserializes to one of the following structs:
     * 1. InitializeSettings
     * 2. DepositAcknowledgement
     * 3. Trade
     * 4. SettlementAcknowledgement
     */
    struct InitializeSettings {
        address tradeSigningKey;
        address feeRecipient;
        uint256 settlementFeeNumerator;
        uint256 interfaceFeeNumerator;
        uint256 feeDenominator;
    }

    struct DepositAcknowledgement {
        Deposit deposit;
        bytes32 depositUtxo;
        bytes32 output;
    }

    struct Trade {
        TradeParams params;
        bytes32[] inputsA;
        bytes32[] inputsB;
        bytes32[] outputsA;
        bytes32[] outputsB;
    }

    struct SettlementAcknowledgement {
        SettlementRequest settlementRequest;
        bytes32[] inputs;
    }

    struct UTXO {
        address trader;
        uint256 amount;
        uint256 stateUpdateId;
        bytes32 parentUtxo;
        bytes32 depositUtxo;
        address participatingInterface;
        address asset;
        uint256 chainId;
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
        uint256 chainSequenceId;
        uint256 chainId;
    }

    struct SettlementRequest {
        address trader;
        address asset;
        address participatingInterface;
        uint256 chainSequenceId;
        uint256 chainId;
        uint256 settlementId;
    }

    struct TradeParams {
        address participatingInterface;
        LimitOrder orderA;
        LimitOrder orderB;
        Product product;
        uint256 size;
        uint256 price;
    }

    struct Product {
        address assetA;
        uint256 chainIdA;
        address assetB;
        uint256 chainIdB;
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
