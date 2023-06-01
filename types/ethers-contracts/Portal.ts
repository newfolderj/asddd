/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PayableOverrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
} from "./common";

export interface PortalInterface extends utils.Interface {
  functions: {
    "availableToWithdraw(address,address)": FunctionFragment;
    "balances(bytes32)": FunctionFragment;
    "chainSequenceId()": FunctionFragment;
    "claimed(bytes32)": FunctionFragment;
    "depositNativeAsset()": FunctionFragment;
    "depositToken(address,uint256)": FunctionFragment;
    "deposits(bytes32)": FunctionFragment;
    "getAvailableBalance(address,address)": FunctionFragment;
    "isValidSettlementRequest(uint256,bytes32)": FunctionFragment;
    "requestSettlement(address)": FunctionFragment;
    "sequenceEvent()": FunctionFragment;
    "settlementRequests(uint256)": FunctionFragment;
    "withdraw(uint256,address)": FunctionFragment;
    "writeObligation(bytes32,bytes32,address,uint256)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "availableToWithdraw"
      | "balances"
      | "chainSequenceId"
      | "claimed"
      | "depositNativeAsset"
      | "depositToken"
      | "deposits"
      | "getAvailableBalance"
      | "isValidSettlementRequest"
      | "requestSettlement"
      | "sequenceEvent"
      | "settlementRequests"
      | "withdraw"
      | "writeObligation"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "availableToWithdraw",
    values: [string, string]
  ): string;
  encodeFunctionData(functionFragment: "balances", values: [BytesLike]): string;
  encodeFunctionData(
    functionFragment: "chainSequenceId",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "claimed", values: [BytesLike]): string;
  encodeFunctionData(
    functionFragment: "depositNativeAsset",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "depositToken",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "deposits", values: [BytesLike]): string;
  encodeFunctionData(
    functionFragment: "getAvailableBalance",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "isValidSettlementRequest",
    values: [BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "requestSettlement",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "sequenceEvent",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "settlementRequests",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "withdraw",
    values: [BigNumberish, string]
  ): string;
  encodeFunctionData(
    functionFragment: "writeObligation",
    values: [BytesLike, BytesLike, string, BigNumberish]
  ): string;

  decodeFunctionResult(
    functionFragment: "availableToWithdraw",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "balances", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "chainSequenceId",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "claimed", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "depositNativeAsset",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "depositToken",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "deposits", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getAvailableBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isValidSettlementRequest",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "requestSettlement",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "sequenceEvent",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "settlementRequests",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "withdraw", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "writeObligation",
    data: BytesLike
  ): Result;

  events: {
    "Deposit(address,uint256,address,uint256)": EventFragment;
    "DepositUtxo(address,uint256,address,address,uint256,bytes32)": EventFragment;
    "ObligationWritten(address,address,address,uint256)": EventFragment;
    "SettlementRequested(uint256,address,address,uint256)": EventFragment;
    "Withdraw(address,uint256,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Deposit"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "DepositUtxo"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ObligationWritten"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "SettlementRequested"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Withdraw"): EventFragment;
}

export interface DepositEventObject {
  wallet: string;
  amount: BigNumber;
  token: string;
  chainSequenceId: BigNumber;
}
export type DepositEvent = TypedEvent<
  [string, BigNumber, string, BigNumber],
  DepositEventObject
>;

export type DepositEventFilter = TypedEventFilter<DepositEvent>;

export interface DepositUtxoEventObject {
  wallet: string;
  amount: BigNumber;
  token: string;
  participatingInterface: string;
  chainSequenceId: BigNumber;
  utxo: string;
}
export type DepositUtxoEvent = TypedEvent<
  [string, BigNumber, string, string, BigNumber, string],
  DepositUtxoEventObject
>;

export type DepositUtxoEventFilter = TypedEventFilter<DepositUtxoEvent>;

export interface ObligationWrittenEventObject {
  deliverer: string;
  recipient: string;
  token: string;
  amount: BigNumber;
}
export type ObligationWrittenEvent = TypedEvent<
  [string, string, string, BigNumber],
  ObligationWrittenEventObject
>;

export type ObligationWrittenEventFilter =
  TypedEventFilter<ObligationWrittenEvent>;

export interface SettlementRequestedEventObject {
  settlementID: BigNumber;
  trader: string;
  token: string;
  chainSequenceId: BigNumber;
}
export type SettlementRequestedEvent = TypedEvent<
  [BigNumber, string, string, BigNumber],
  SettlementRequestedEventObject
>;

export type SettlementRequestedEventFilter =
  TypedEventFilter<SettlementRequestedEvent>;

export interface WithdrawEventObject {
  wallet: string;
  amount: BigNumber;
  token: string;
}
export type WithdrawEvent = TypedEvent<
  [string, BigNumber, string],
  WithdrawEventObject
>;

export type WithdrawEventFilter = TypedEventFilter<WithdrawEvent>;

export interface Portal extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: PortalInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    availableToWithdraw(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    balances(arg0: BytesLike, overrides?: CallOverrides): Promise<[BigNumber]>;

    chainSequenceId(overrides?: CallOverrides): Promise<[BigNumber]>;

    claimed(arg0: BytesLike, overrides?: CallOverrides): Promise<[boolean]>;

    depositNativeAsset(
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;

    depositToken(
      _token: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    deposits(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<
      [string, string, string, BigNumber, BigNumber, BigNumber] & {
        trader: string;
        asset: string;
        participatingInterface: string;
        amount: BigNumber;
        chainSequenceId: BigNumber;
        chainId: BigNumber;
      }
    >;

    getAvailableBalance(
      _trader: string,
      _token: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    isValidSettlementRequest(
      _chainSequenceId: BigNumberish,
      _settlementHash: BytesLike,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    requestSettlement(
      _token: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    sequenceEvent(
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    settlementRequests(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [string, string, string, BigNumber, BigNumber, BigNumber] & {
        trader: string;
        asset: string;
        participatingInterface: string;
        chainSequenceId: BigNumber;
        chainId: BigNumber;
        settlementId: BigNumber;
      }
    >;

    withdraw(
      _amount: BigNumberish,
      _token: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    writeObligation(
      _utxo: BytesLike,
      _deposit: BytesLike,
      _recipient: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;
  };

  availableToWithdraw(
    arg0: string,
    arg1: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  balances(arg0: BytesLike, overrides?: CallOverrides): Promise<BigNumber>;

  chainSequenceId(overrides?: CallOverrides): Promise<BigNumber>;

  claimed(arg0: BytesLike, overrides?: CallOverrides): Promise<boolean>;

  depositNativeAsset(
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  depositToken(
    _token: string,
    _amount: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  deposits(
    arg0: BytesLike,
    overrides?: CallOverrides
  ): Promise<
    [string, string, string, BigNumber, BigNumber, BigNumber] & {
      trader: string;
      asset: string;
      participatingInterface: string;
      amount: BigNumber;
      chainSequenceId: BigNumber;
      chainId: BigNumber;
    }
  >;

  getAvailableBalance(
    _trader: string,
    _token: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  isValidSettlementRequest(
    _chainSequenceId: BigNumberish,
    _settlementHash: BytesLike,
    overrides?: CallOverrides
  ): Promise<boolean>;

  requestSettlement(
    _token: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  sequenceEvent(
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  settlementRequests(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [string, string, string, BigNumber, BigNumber, BigNumber] & {
      trader: string;
      asset: string;
      participatingInterface: string;
      chainSequenceId: BigNumber;
      chainId: BigNumber;
      settlementId: BigNumber;
    }
  >;

  withdraw(
    _amount: BigNumberish,
    _token: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  writeObligation(
    _utxo: BytesLike,
    _deposit: BytesLike,
    _recipient: string,
    _amount: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  callStatic: {
    availableToWithdraw(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    balances(arg0: BytesLike, overrides?: CallOverrides): Promise<BigNumber>;

    chainSequenceId(overrides?: CallOverrides): Promise<BigNumber>;

    claimed(arg0: BytesLike, overrides?: CallOverrides): Promise<boolean>;

    depositNativeAsset(overrides?: CallOverrides): Promise<void>;

    depositToken(
      _token: string,
      _amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    deposits(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<
      [string, string, string, BigNumber, BigNumber, BigNumber] & {
        trader: string;
        asset: string;
        participatingInterface: string;
        amount: BigNumber;
        chainSequenceId: BigNumber;
        chainId: BigNumber;
      }
    >;

    getAvailableBalance(
      _trader: string,
      _token: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isValidSettlementRequest(
      _chainSequenceId: BigNumberish,
      _settlementHash: BytesLike,
      overrides?: CallOverrides
    ): Promise<boolean>;

    requestSettlement(_token: string, overrides?: CallOverrides): Promise<void>;

    sequenceEvent(overrides?: CallOverrides): Promise<BigNumber>;

    settlementRequests(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [string, string, string, BigNumber, BigNumber, BigNumber] & {
        trader: string;
        asset: string;
        participatingInterface: string;
        chainSequenceId: BigNumber;
        chainId: BigNumber;
        settlementId: BigNumber;
      }
    >;

    withdraw(
      _amount: BigNumberish,
      _token: string,
      overrides?: CallOverrides
    ): Promise<void>;

    writeObligation(
      _utxo: BytesLike,
      _deposit: BytesLike,
      _recipient: string,
      _amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "Deposit(address,uint256,address,uint256)"(
      wallet?: null,
      amount?: null,
      token?: null,
      chainSequenceId?: null
    ): DepositEventFilter;
    Deposit(
      wallet?: null,
      amount?: null,
      token?: null,
      chainSequenceId?: null
    ): DepositEventFilter;

    "DepositUtxo(address,uint256,address,address,uint256,bytes32)"(
      wallet?: null,
      amount?: null,
      token?: null,
      participatingInterface?: null,
      chainSequenceId?: null,
      utxo?: null
    ): DepositUtxoEventFilter;
    DepositUtxo(
      wallet?: null,
      amount?: null,
      token?: null,
      participatingInterface?: null,
      chainSequenceId?: null,
      utxo?: null
    ): DepositUtxoEventFilter;

    "ObligationWritten(address,address,address,uint256)"(
      deliverer?: null,
      recipient?: null,
      token?: null,
      amount?: null
    ): ObligationWrittenEventFilter;
    ObligationWritten(
      deliverer?: null,
      recipient?: null,
      token?: null,
      amount?: null
    ): ObligationWrittenEventFilter;

    "SettlementRequested(uint256,address,address,uint256)"(
      settlementID?: null,
      trader?: null,
      token?: null,
      chainSequenceId?: null
    ): SettlementRequestedEventFilter;
    SettlementRequested(
      settlementID?: null,
      trader?: null,
      token?: null,
      chainSequenceId?: null
    ): SettlementRequestedEventFilter;

    "Withdraw(address,uint256,address)"(
      wallet?: null,
      amount?: null,
      token?: null
    ): WithdrawEventFilter;
    Withdraw(wallet?: null, amount?: null, token?: null): WithdrawEventFilter;
  };

  estimateGas: {
    availableToWithdraw(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    balances(arg0: BytesLike, overrides?: CallOverrides): Promise<BigNumber>;

    chainSequenceId(overrides?: CallOverrides): Promise<BigNumber>;

    claimed(arg0: BytesLike, overrides?: CallOverrides): Promise<BigNumber>;

    depositNativeAsset(
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;

    depositToken(
      _token: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    deposits(arg0: BytesLike, overrides?: CallOverrides): Promise<BigNumber>;

    getAvailableBalance(
      _trader: string,
      _token: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isValidSettlementRequest(
      _chainSequenceId: BigNumberish,
      _settlementHash: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    requestSettlement(
      _token: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    sequenceEvent(
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    settlementRequests(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    withdraw(
      _amount: BigNumberish,
      _token: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    writeObligation(
      _utxo: BytesLike,
      _deposit: BytesLike,
      _recipient: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    availableToWithdraw(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    balances(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    chainSequenceId(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    claimed(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    depositNativeAsset(
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    depositToken(
      _token: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    deposits(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getAvailableBalance(
      _trader: string,
      _token: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isValidSettlementRequest(
      _chainSequenceId: BigNumberish,
      _settlementHash: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    requestSettlement(
      _token: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    sequenceEvent(
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    settlementRequests(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    withdraw(
      _amount: BigNumberish,
      _token: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    writeObligation(
      _utxo: BytesLike,
      _deposit: BytesLike,
      _recipient: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;
  };
}
