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

  export type UTXOStruct = {
    trader: string;
    amount: BigNumberish;
    stateUpdateId: BigNumberish;
    parentUtxo: BytesLike;
    depositUtxo: BytesLike;
    participatingInterface: string;
    asset: string;
    chainId: BigNumberish;
  };

  export type UTXOStructOutput = [
    string,
    BigNumber,
    BigNumber,
    string,
    string,
    string,
    string,
    BigNumber
  ] & {
    trader: string;
    amount: BigNumber;
    stateUpdateId: BigNumber;
    parentUtxo: string;
    depositUtxo: string;
    participatingInterface: string;
    asset: string;
    chainId: BigNumber;
  };
}

export interface RollupInterface extends utils.Interface {
  functions: {
    "CONFIRMATION_BLOCKS()": FunctionFragment;
    "confirmStateRoot()": FunctionFragment;
    "confirmedStateRoot(uint256)": FunctionFragment;
    "epoch()": FunctionFragment;
    "fraudulent(uint256,bytes32)": FunctionFragment;
    "getConfirmedStateRoot(uint256)": FunctionFragment;
    "getCurrentEpoch()": FunctionFragment;
    "getProposedStateRoot(uint256)": FunctionFragment;
    "lastConfirmedEpoch()": FunctionFragment;
    "lastSettlementIdProcessed()": FunctionFragment;
    "markFraudulent(uint256)": FunctionFragment;
    "nextRequestId()": FunctionFragment;
    "processSettlement(((uint8,uint256,address,bytes),uint8,bytes32,bytes32),uint256,bytes32[],(address,uint256,uint256,bytes32,bytes32,address,address,uint256)[])": FunctionFragment;
    "proposalBlock(bytes32)": FunctionFragment;
    "proposeStateRoot(bytes32)": FunctionFragment;
    "proposedStateRoot(uint256)": FunctionFragment;
    "requestSettlement(address,address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "CONFIRMATION_BLOCKS"
      | "confirmStateRoot"
      | "confirmedStateRoot"
      | "epoch"
      | "fraudulent"
      | "getConfirmedStateRoot"
      | "getCurrentEpoch"
      | "getProposedStateRoot"
      | "lastConfirmedEpoch"
      | "lastSettlementIdProcessed"
      | "markFraudulent"
      | "nextRequestId"
      | "processSettlement"
      | "proposalBlock"
      | "proposeStateRoot"
      | "proposedStateRoot"
      | "requestSettlement"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "CONFIRMATION_BLOCKS",
    values?: undefined
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
    functionFragment: "lastConfirmedEpoch",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "lastSettlementIdProcessed",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "markFraudulent",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "nextRequestId",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "processSettlement",
    values: [
      StateUpdateLibrary.SignedStateUpdateStruct,
      BigNumberish,
      BytesLike[],
      StateUpdateLibrary.UTXOStruct[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "proposalBlock",
    values: [BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "proposeStateRoot",
    values: [BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "proposedStateRoot",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "requestSettlement",
    values: [string, string]
  ): string;

  decodeFunctionResult(
    functionFragment: "CONFIRMATION_BLOCKS",
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
    functionFragment: "lastConfirmedEpoch",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "lastSettlementIdProcessed",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "markFraudulent",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "nextRequestId",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "processSettlement",
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
    functionFragment: "requestSettlement",
    data: BytesLike
  ): Result;

  events: {
    "ObligationsWritten(uint256,address,address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "ObligationsWritten"): EventFragment;
}

export interface ObligationsWrittenEventObject {
  id: BigNumber;
  requester: string;
  token: string;
  cleared: BigNumber;
}
export type ObligationsWrittenEvent = TypedEvent<
  [BigNumber, string, string, BigNumber],
  ObligationsWrittenEventObject
>;

export type ObligationsWrittenEventFilter =
  TypedEventFilter<ObligationsWrittenEvent>;

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
    CONFIRMATION_BLOCKS(overrides?: CallOverrides): Promise<[BigNumber]>;

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

    lastConfirmedEpoch(overrides?: CallOverrides): Promise<[BigNumber]>;

    lastSettlementIdProcessed(overrides?: CallOverrides): Promise<[BigNumber]>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    nextRequestId(overrides?: CallOverrides): Promise<[BigNumber]>;

    processSettlement(
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _stateRootId: BigNumberish,
      _proof: BytesLike[],
      _inputs: StateUpdateLibrary.UTXOStruct[],
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    proposalBlock(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    proposeStateRoot(
      _stateRoot: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string]>;

    requestSettlement(
      arg0: string,
      arg1: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;
  };

  CONFIRMATION_BLOCKS(overrides?: CallOverrides): Promise<BigNumber>;

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

  lastConfirmedEpoch(overrides?: CallOverrides): Promise<BigNumber>;

  lastSettlementIdProcessed(overrides?: CallOverrides): Promise<BigNumber>;

  markFraudulent(
    _epoch: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  nextRequestId(overrides?: CallOverrides): Promise<BigNumber>;

  processSettlement(
    _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
    _stateRootId: BigNumberish,
    _proof: BytesLike[],
    _inputs: StateUpdateLibrary.UTXOStruct[],
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  proposalBlock(arg0: BytesLike, overrides?: CallOverrides): Promise<BigNumber>;

  proposeStateRoot(
    _stateRoot: BytesLike,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  proposedStateRoot(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<string>;

  requestSettlement(
    arg0: string,
    arg1: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  callStatic: {
    CONFIRMATION_BLOCKS(overrides?: CallOverrides): Promise<BigNumber>;

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

    lastConfirmedEpoch(overrides?: CallOverrides): Promise<BigNumber>;

    lastSettlementIdProcessed(overrides?: CallOverrides): Promise<BigNumber>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    nextRequestId(overrides?: CallOverrides): Promise<BigNumber>;

    processSettlement(
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _stateRootId: BigNumberish,
      _proof: BytesLike[],
      _inputs: StateUpdateLibrary.UTXOStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    proposalBlock(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    proposeStateRoot(
      _stateRoot: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<string>;

    requestSettlement(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  filters: {
    "ObligationsWritten(uint256,address,address,uint256)"(
      id?: null,
      requester?: null,
      token?: null,
      cleared?: null
    ): ObligationsWrittenEventFilter;
    ObligationsWritten(
      id?: null,
      requester?: null,
      token?: null,
      cleared?: null
    ): ObligationsWrittenEventFilter;
  };

  estimateGas: {
    CONFIRMATION_BLOCKS(overrides?: CallOverrides): Promise<BigNumber>;

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

    lastConfirmedEpoch(overrides?: CallOverrides): Promise<BigNumber>;

    lastSettlementIdProcessed(overrides?: CallOverrides): Promise<BigNumber>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    nextRequestId(overrides?: CallOverrides): Promise<BigNumber>;

    processSettlement(
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _stateRootId: BigNumberish,
      _proof: BytesLike[],
      _inputs: StateUpdateLibrary.UTXOStruct[],
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    proposalBlock(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    proposeStateRoot(
      _stateRoot: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    requestSettlement(
      arg0: string,
      arg1: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    CONFIRMATION_BLOCKS(
      overrides?: CallOverrides
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

    lastConfirmedEpoch(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    lastSettlementIdProcessed(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    markFraudulent(
      _epoch: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    nextRequestId(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    processSettlement(
      _signedUpdate: StateUpdateLibrary.SignedStateUpdateStruct,
      _stateRootId: BigNumberish,
      _proof: BytesLike[],
      _inputs: StateUpdateLibrary.UTXOStruct[],
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    proposalBlock(
      arg0: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    proposeStateRoot(
      _stateRoot: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    proposedStateRoot(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    requestSettlement(
      arg0: string,
      arg1: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;
  };
}
