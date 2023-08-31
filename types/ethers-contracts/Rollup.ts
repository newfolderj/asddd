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

export declare namespace StateUpdateLibrary {
  export type StateUpdateStruct = {
    typeIdentifier: BigNumberish;
    sequenceId: BigNumberish;
    participatingInterface: string;
    structData: BytesLike;
  };

  export type StateUpdateStructOutput = [number, BigNumber, string, string] & {
    typeIdentifier: number;
    sequenceId: BigNumber;
    participatingInterface: string;
    structData: string;
  };

  export type SignedStateUpdateStruct = {
    stateUpdate: StateUpdateLibrary.StateUpdateStruct;
    v: BigNumberish;
    r: BytesLike;
    s: BytesLike;
  };

  export type SignedStateUpdateStructOutput = [
    StateUpdateLibrary.StateUpdateStructOutput,
    number,
    string,
    string
  ] & {
    stateUpdate: StateUpdateLibrary.StateUpdateStructOutput;
    v: number;
    r: string;
    s: string;
  };
}

export declare namespace Rollup {
  export type TradeProofStruct = {
    tradeUpdate: StateUpdateLibrary.SignedStateUpdateStruct;
    proof: BytesLike[];
  };

  export type TradeProofStructOutput = [
    StateUpdateLibrary.SignedStateUpdateStructOutput,
    string[]
  ] & {
    tradeUpdate: StateUpdateLibrary.SignedStateUpdateStructOutput;
    proof: string[];
  };

  export type TradingFeeClaimStruct = {
    epoch: BigNumberish;
    tradeProof: Rollup.TradeProofStruct[];
  };

  export type TradingFeeClaimStructOutput = [
    BigNumber,
    Rollup.TradeProofStructOutput[]
  ] & { epoch: BigNumber; tradeProof: Rollup.TradeProofStructOutput[] };

  export type RejectedDepositParamsStruct = {
    signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct;
    stateRootId: BigNumberish;
    proof: BytesLike[];
  };

  export type RejectedDepositParamsStructOutput = [
    StateUpdateLibrary.SignedStateUpdateStructOutput,
    BigNumber,
    string[]
  ] & {
    signedUpdate: StateUpdateLibrary.SignedStateUpdateStructOutput;
    stateRootId: BigNumber;
    proof: string[];
  };

  export type SettlementParamsStruct = {
    signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct;
    stateRootId: BigNumberish;
    proof: BytesLike[];
  };

  export type SettlementParamsStructOutput = [
    StateUpdateLibrary.SignedStateUpdateStructOutput,
    BigNumber,
    string[]
  ] & {
    signedUpdate: StateUpdateLibrary.SignedStateUpdateStructOutput;
    stateRootId: BigNumber;
    proof: string[];
  };
}

export interface RollupInterface extends utils.Interface {
  functions: {
    "claimTradingFees((uint256,(((uint8,uint256,address,bytes),uint8,bytes32,bytes32),bytes32[])[])[])": FunctionFragment;
    "confirmStateRoot()": FunctionFragment;
    "confirmedStateRoot(uint256)": FunctionFragment;
    "epoch()": FunctionFragment;
    "fraudulent(uint256,bytes32)": FunctionFragment;
    "getConfirmedStateRoot(uint256)": FunctionFragment;
    "getCurrentEpoch()": FunctionFragment;
    "getProposedStateRoot(uint256)": FunctionFragment;
    "isConfirmedLockId(uint256)": FunctionFragment;
    "isFraudulentLockId(uint256)": FunctionFragment;
    "lastConfirmedEpoch()": FunctionFragment;
    "markFraudulent(uint256)": FunctionFragment;
    "processRejectedDeposits(uint256,(((uint8,uint256,address,bytes),uint8,bytes32,bytes32),uint256,bytes32[])[],bytes)": FunctionFragment;
    "processSettlements(uint256,(((uint8,uint256,address,bytes),uint8,bytes32,bytes32),uint256,bytes32[])[])": FunctionFragment;
    "proposalBlock(uint256,bytes32)": FunctionFragment;
    "proposeStateRoot(bytes32,bytes32)": FunctionFragment;
    "proposedStateRoot(uint256)": FunctionFragment;
    "relayTradingFees(uint256,address[],bytes)": FunctionFragment;
    "replaceStateRoot(bytes32,uint256)": FunctionFragment;
    "submitSettlement(bytes32,((uint8,uint256,address,bytes),uint8,bytes32,bytes32),bytes32[])": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "claimTradingFees"
      | "confirmStateRoot"
      | "confirmedStateRoot"
      | "epoch"
      | "fraudulent"
      | "getConfirmedStateRoot"
      | "getCurrentEpoch"
      | "getProposedStateRoot"
      | "isConfirmedLockId"
      | "isFraudulentLockId"
      | "lastConfirmedEpoch"
      | "markFraudulent"
      | "processRejectedDeposits"
      | "processSettlements"
      | "proposalBlock"
      | "proposeStateRoot"
      | "proposedStateRoot"
      | "relayTradingFees"
      | "replaceStateRoot"
      | "submitSettlement"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "claimTradingFees",
    values: [Rollup.TradingFeeClaimStruct[]]
  ): string;
  encodeFunctionData(
    functionFragment: "confirmStateRoot",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "confirmedStateRoot",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "epoch", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "fraudulent",
    values: [BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getConfirmedStateRoot",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getCurrentEpoch",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getProposedStateRoot",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "isConfirmedLockId",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "isFraudulentLockId",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "lastConfirmedEpoch",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "markFraudulent",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "processRejectedDeposits",
    values: [BigNumberish, Rollup.RejectedDepositParamsStruct[], BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "processSettlements",
    values: [BigNumberish, Rollup.SettlementParamsStruct[]]
  ): string;
  encodeFunctionData(
    functionFragment: "proposalBlock",
    values: [BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "proposeStateRoot",
    values: [BytesLike, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "proposedStateRoot",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "relayTradingFees",
    values: [BigNumberish, string[], BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "replaceStateRoot",
    values: [BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "submitSettlement",
    values: [BytesLike, StateUpdateLibrary.SignedStateUpdateStruct, BytesLike[]]
  ): string;

  decodeFunctionResult(
    functionFragment: "claimTradingFees",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "confirmStateRoot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "confirmedStateRoot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "epoch", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "fraudulent", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getConfirmedStateRoot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getCurrentEpoch",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getProposedStateRoot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isConfirmedLockId",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isFraudulentLockId",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "lastConfirmedEpoch",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "markFraudulent",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "processRejectedDeposits",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "processSettlements",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "proposalBlock",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "proposeStateRoot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "proposedStateRoot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "relayTradingFees",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "replaceStateRoot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "submitSettlement",
    data: BytesLike
  ): Result;

  events: {
    "SettlementFeePaid(address,uint256,address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "SettlementFeePaid"): EventFragment;
}

export interface SettlementFeePaidEventObject {
  trader: string;
  chainId: BigNumber;
  token: string;
  amount: BigNumber;
}
export type SettlementFeePaidEvent = TypedEvent<
  [string, BigNumber, string, BigNumber],
  SettlementFeePaidEventObject
>;

export type SettlementFeePaidEventFilter =
  TypedEventFilter<SettlementFeePaidEvent>;

export interface Rollup extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: RollupInterface;

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
    claimTradingFees(
      _claims: Rollup.TradingFeeClaimStruct[],
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    confirmStateRoot(
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    confirmedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string]>;

    epoch(overrides?: CallOverrides): Promise<[BigNumber]>;

    fraudulent(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    getConfirmedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string] & { root: string }>;

    getCurrentEpoch(overrides?: CallOverrides): Promise<[BigNumber]>;

    getProposedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string] & { root: string }>;

    isConfirmedLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isFraudulentLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    lastConfirmedEpoch(overrides?: CallOverrides): Promise<[BigNumber]>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    processRejectedDeposits(
      _chainId: BigNumberish,
      _params: Rollup.RejectedDepositParamsStruct[],
      adapterParams: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;

    processSettlements(
      _chainId: BigNumberish,
      _params: Rollup.SettlementParamsStruct[],
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;

    proposalBlock(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    proposeStateRoot(
      _lastProposedStateRoot: BytesLike,
      _stateRoot: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string]>;

    relayTradingFees(
      _chainId: BigNumberish,
      _assets: string[],
      _adapterParans: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;

    replaceStateRoot(
      _stateRoot: BytesLike,
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    submitSettlement(
      _stateRoot: BytesLike,
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _proof: BytesLike[],
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;
  };

  claimTradingFees(
    _claims: Rollup.TradingFeeClaimStruct[],
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  confirmStateRoot(
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  confirmedStateRoot(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<string>;

  epoch(overrides?: CallOverrides): Promise<BigNumber>;

  fraudulent(
    arg0: BigNumberish,
    arg1: BytesLike,
    overrides?: CallOverrides
  ): Promise<boolean>;

  getConfirmedStateRoot(
    _epoch: BigNumberish,
    overrides?: CallOverrides
  ): Promise<string>;

  getCurrentEpoch(overrides?: CallOverrides): Promise<BigNumber>;

  getProposedStateRoot(
    _epoch: BigNumberish,
    overrides?: CallOverrides
  ): Promise<string>;

  isConfirmedLockId(
    _lockId: BigNumberish,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isFraudulentLockId(
    _lockId: BigNumberish,
    overrides?: CallOverrides
  ): Promise<boolean>;

  lastConfirmedEpoch(overrides?: CallOverrides): Promise<BigNumber>;

  markFraudulent(
    _epoch: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  processRejectedDeposits(
    _chainId: BigNumberish,
    _params: Rollup.RejectedDepositParamsStruct[],
    adapterParams: BytesLike,
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  processSettlements(
    _chainId: BigNumberish,
    _params: Rollup.SettlementParamsStruct[],
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  proposalBlock(
    arg0: BigNumberish,
    arg1: BytesLike,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  proposeStateRoot(
    _lastProposedStateRoot: BytesLike,
    _stateRoot: BytesLike,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  proposedStateRoot(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<string>;

  relayTradingFees(
    _chainId: BigNumberish,
    _assets: string[],
    _adapterParans: BytesLike,
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  replaceStateRoot(
    _stateRoot: BytesLike,
    _epoch: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  submitSettlement(
    _stateRoot: BytesLike,
    _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
    _proof: BytesLike[],
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  callStatic: {
    claimTradingFees(
      _claims: Rollup.TradingFeeClaimStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    confirmStateRoot(overrides?: CallOverrides): Promise<void>;

    confirmedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<string>;

    epoch(overrides?: CallOverrides): Promise<BigNumber>;

    fraudulent(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<boolean>;

    getConfirmedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<string>;

    getCurrentEpoch(overrides?: CallOverrides): Promise<BigNumber>;

    getProposedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<string>;

    isConfirmedLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isFraudulentLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<boolean>;

    lastConfirmedEpoch(overrides?: CallOverrides): Promise<BigNumber>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    processRejectedDeposits(
      _chainId: BigNumberish,
      _params: Rollup.RejectedDepositParamsStruct[],
      adapterParams: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    processSettlements(
      _chainId: BigNumberish,
      _params: Rollup.SettlementParamsStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    proposalBlock(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    proposeStateRoot(
      _lastProposedStateRoot: BytesLike,
      _stateRoot: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<string>;

    relayTradingFees(
      _chainId: BigNumberish,
      _assets: string[],
      _adapterParans: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    replaceStateRoot(
      _stateRoot: BytesLike,
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    submitSettlement(
      _stateRoot: BytesLike,
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _proof: BytesLike[],
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "SettlementFeePaid(address,uint256,address,uint256)"(
      trader?: string | null,
      chainId?: BigNumberish | null,
      token?: string | null,
      amount?: null
    ): SettlementFeePaidEventFilter;
    SettlementFeePaid(
      trader?: string | null,
      chainId?: BigNumberish | null,
      token?: string | null,
      amount?: null
    ): SettlementFeePaidEventFilter;
  };

  estimateGas: {
    claimTradingFees(
      _claims: Rollup.TradingFeeClaimStruct[],
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    confirmStateRoot(
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    confirmedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    epoch(overrides?: CallOverrides): Promise<BigNumber>;

    fraudulent(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getConfirmedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getCurrentEpoch(overrides?: CallOverrides): Promise<BigNumber>;

    getProposedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isConfirmedLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isFraudulentLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    lastConfirmedEpoch(overrides?: CallOverrides): Promise<BigNumber>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    processRejectedDeposits(
      _chainId: BigNumberish,
      _params: Rollup.RejectedDepositParamsStruct[],
      adapterParams: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;

    processSettlements(
      _chainId: BigNumberish,
      _params: Rollup.SettlementParamsStruct[],
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;

    proposalBlock(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    proposeStateRoot(
      _lastProposedStateRoot: BytesLike,
      _stateRoot: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    relayTradingFees(
      _chainId: BigNumberish,
      _assets: string[],
      _adapterParans: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;

    replaceStateRoot(
      _stateRoot: BytesLike,
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    submitSettlement(
      _stateRoot: BytesLike,
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _proof: BytesLike[],
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    claimTradingFees(
      _claims: Rollup.TradingFeeClaimStruct[],
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    confirmStateRoot(
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    confirmedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    epoch(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    fraudulent(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getConfirmedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getCurrentEpoch(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getProposedStateRoot(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isConfirmedLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isFraudulentLockId(
      _lockId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    lastConfirmedEpoch(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    processRejectedDeposits(
      _chainId: BigNumberish,
      _params: Rollup.RejectedDepositParamsStruct[],
      adapterParams: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    processSettlements(
      _chainId: BigNumberish,
      _params: Rollup.SettlementParamsStruct[],
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    proposalBlock(
      arg0: BigNumberish,
      arg1: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    proposeStateRoot(
      _lastProposedStateRoot: BytesLike,
      _stateRoot: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    relayTradingFees(
      _chainId: BigNumberish,
      _assets: string[],
      _adapterParans: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    replaceStateRoot(
      _stateRoot: BytesLike,
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    submitSettlement(
      _stateRoot: BytesLike,
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _proof: BytesLike[],
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;
  };
}
