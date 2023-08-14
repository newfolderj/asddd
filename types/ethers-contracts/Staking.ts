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
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
} from "./common";

export declare namespace Staking {
  export type ClaimParamsStruct = {
    lockId: BigNumberish[];
    depositId: BigNumberish[];
    rewardChainId: BigNumberish;
    rewardAsset: string[];
  };

  export type ClaimParamsStructOutput = [
    BigNumber[],
    BigNumber[],
    BigNumber,
    string[]
  ] & {
    lockId: BigNumber[];
    depositId: BigNumber[];
    rewardChainId: BigNumber;
    rewardAsset: string[];
  };

  export type LockRecordStruct = {
    amountLocked: BigNumberish;
    totalAmountStaked: BigNumberish;
    blockNumber: BigNumberish;
    asset: string;
  };

  export type LockRecordStructOutput = [
    BigNumber,
    BigNumber,
    BigNumber,
    string
  ] & {
    amountLocked: BigNumber;
    totalAmountStaked: BigNumber;
    blockNumber: BigNumber;
    asset: string;
  };

  export type DepositRecordStruct = {
    staker: string;
    asset: string;
    amount: BigNumberish;
    blockNumber: BigNumberish;
    unlockTime: BigNumberish;
    withdrawn: BigNumberish;
  };

  export type DepositRecordStructOutput = [
    string,
    string,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber
  ] & {
    staker: string;
    asset: string;
    amount: BigNumber;
    blockNumber: BigNumber;
    unlockTime: BigNumber;
    withdrawn: BigNumber;
  };
}

export interface StakingInterface extends utils.Interface {
  functions: {
    "ACTIVE_PERIODS()": FunctionFragment;
    "PERIOD_LENGTH()": FunctionFragment;
    "claim((uint256[],uint256[],uint256,address[]))": FunctionFragment;
    "currentDepositId()": FunctionFragment;
    "currentLockId()": FunctionFragment;
    "deposits(uint256)": FunctionFragment;
    "getActiveTranches()": FunctionFragment;
    "getActiveTranches(uint256)": FunctionFragment;
    "getAllLockRecords()": FunctionFragment;
    "getAvailableToClaim(address,uint256,address)": FunctionFragment;
    "getLockRecords(uint256,uint256)": FunctionFragment;
    "getUnlocked(address)": FunctionFragment;
    "getUserDepositIds(address)": FunctionFragment;
    "getUserDepositRecords(address)": FunctionFragment;
    "individualStaked(address,address)": FunctionFragment;
    "lock(address,uint256)": FunctionFragment;
    "locks(uint256)": FunctionFragment;
    "minimumProtocolStake()": FunctionFragment;
    "minimumStablecoinStake()": FunctionFragment;
    "nextIdToUnlock()": FunctionFragment;
    "payInsurance(uint256,address,uint256)": FunctionFragment;
    "protocolToken()": FunctionFragment;
    "reward(uint256,uint256,address,uint256)": FunctionFragment;
    "slash(uint256)": FunctionFragment;
    "stablecoin()": FunctionFragment;
    "stake(address,uint256,uint256)": FunctionFragment;
    "totalStaked(address)": FunctionFragment;
    "unlock(uint256[])": FunctionFragment;
    "withdraw(uint256[])": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "ACTIVE_PERIODS"
      | "PERIOD_LENGTH"
      | "claim"
      | "currentDepositId"
      | "currentLockId"
      | "deposits"
      | "getActiveTranches()"
      | "getActiveTranches(uint256)"
      | "getAllLockRecords"
      | "getAvailableToClaim"
      | "getLockRecords"
      | "getUnlocked"
      | "getUserDepositIds"
      | "getUserDepositRecords"
      | "individualStaked"
      | "lock"
      | "locks"
      | "minimumProtocolStake"
      | "minimumStablecoinStake"
      | "nextIdToUnlock"
      | "payInsurance"
      | "protocolToken"
      | "reward"
      | "slash"
      | "stablecoin"
      | "stake"
      | "totalStaked"
      | "unlock"
      | "withdraw"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "ACTIVE_PERIODS",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "PERIOD_LENGTH",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "claim",
    values: [Staking.ClaimParamsStruct]
  ): string;
  encodeFunctionData(
    functionFragment: "currentDepositId",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "currentLockId",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "deposits",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getActiveTranches()",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getActiveTranches(uint256)",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getAllLockRecords",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getAvailableToClaim",
    values: [string, BigNumberish, string]
  ): string;
  encodeFunctionData(
    functionFragment: "getLockRecords",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "getUnlocked", values: [string]): string;
  encodeFunctionData(
    functionFragment: "getUserDepositIds",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "getUserDepositRecords",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "individualStaked",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "lock",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "locks", values: [BigNumberish]): string;
  encodeFunctionData(
    functionFragment: "minimumProtocolStake",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "minimumStablecoinStake",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "nextIdToUnlock",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "payInsurance",
    values: [BigNumberish, string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "protocolToken",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "reward",
    values: [BigNumberish, BigNumberish, string, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "slash", values: [BigNumberish]): string;
  encodeFunctionData(
    functionFragment: "stablecoin",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "stake",
    values: [string, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "totalStaked", values: [string]): string;
  encodeFunctionData(
    functionFragment: "unlock",
    values: [BigNumberish[]]
  ): string;
  encodeFunctionData(
    functionFragment: "withdraw",
    values: [BigNumberish[]]
  ): string;

  decodeFunctionResult(
    functionFragment: "ACTIVE_PERIODS",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "PERIOD_LENGTH",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "claim", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "currentDepositId",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "currentLockId",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "deposits", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getActiveTranches()",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getActiveTranches(uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getAllLockRecords",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getAvailableToClaim",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getLockRecords",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getUnlocked",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getUserDepositIds",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getUserDepositRecords",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "individualStaked",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "lock", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "locks", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "minimumProtocolStake",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "minimumStablecoinStake",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "nextIdToUnlock",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "payInsurance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "protocolToken",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "reward", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "slash", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "stablecoin", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "stake", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "totalStaked",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "unlock", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "withdraw", data: BytesLike): Result;

  events: {};
}

export interface Staking extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: StakingInterface;

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
    ACTIVE_PERIODS(overrides?: CallOverrides): Promise<[BigNumber]>;

    PERIOD_LENGTH(overrides?: CallOverrides): Promise<[BigNumber]>;

    claim(
      _params: Staking.ClaimParamsStruct,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;

    currentDepositId(overrides?: CallOverrides): Promise<[BigNumber]>;

    currentLockId(overrides?: CallOverrides): Promise<[BigNumber]>;

    deposits(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [string, string, BigNumber, BigNumber, BigNumber, BigNumber] & {
        staker: string;
        asset: string;
        amount: BigNumber;
        blockNumber: BigNumber;
        unlockTime: BigNumber;
        withdrawn: BigNumber;
      }
    >;

    "getActiveTranches()"(
      overrides?: CallOverrides
    ): Promise<
      [[BigNumber, BigNumber, BigNumber]] & {
        tranches: [BigNumber, BigNumber, BigNumber];
      }
    >;

    "getActiveTranches(uint256)"(
      _blockNumber: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [[BigNumber, BigNumber, BigNumber]] & {
        tranches: [BigNumber, BigNumber, BigNumber];
      }
    >;

    getAllLockRecords(
      overrides?: CallOverrides
    ): Promise<[Staking.LockRecordStructOutput[]]>;

    getAvailableToClaim(
      _staker: string,
      _chainId: BigNumberish,
      _asset: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber] & { availableToClaim: BigNumber }>;

    getLockRecords(
      _from: BigNumberish,
      _to: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[Staking.LockRecordStructOutput[]]>;

    getUnlocked(
      _staker: string,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber] & {
        stablecoinUnlocked: BigNumber;
        protocolUnlocked: BigNumber;
      }
    >;

    getUserDepositIds(
      _user: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber[]]>;

    getUserDepositRecords(
      _user: string,
      overrides?: CallOverrides
    ): Promise<[Staking.DepositRecordStructOutput[]]>;

    individualStaked(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    lock(
      _asset: string,
      _amountToLock: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    locks(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, BigNumber, string] & {
        amountLocked: BigNumber;
        totalAmountStaked: BigNumber;
        blockNumber: BigNumber;
        asset: string;
      }
    >;

    minimumProtocolStake(overrides?: CallOverrides): Promise<[BigNumber]>;

    minimumStablecoinStake(overrides?: CallOverrides): Promise<[BigNumber]>;

    nextIdToUnlock(overrides?: CallOverrides): Promise<[BigNumber]>;

    payInsurance(
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    protocolToken(overrides?: CallOverrides): Promise<[string]>;

    reward(
      _lockId: BigNumberish,
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    slash(
      _lockId: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    stablecoin(overrides?: CallOverrides): Promise<[string]>;

    stake(
      _asset: string,
      _amount: BigNumberish,
      _unlockTime: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    totalStaked(arg0: string, overrides?: CallOverrides): Promise<[BigNumber]>;

    unlock(
      _lockIds: BigNumberish[],
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    withdraw(
      _depositIds: BigNumberish[],
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;
  };

  ACTIVE_PERIODS(overrides?: CallOverrides): Promise<BigNumber>;

  PERIOD_LENGTH(overrides?: CallOverrides): Promise<BigNumber>;

  claim(
    _params: Staking.ClaimParamsStruct,
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  currentDepositId(overrides?: CallOverrides): Promise<BigNumber>;

  currentLockId(overrides?: CallOverrides): Promise<BigNumber>;

  deposits(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [string, string, BigNumber, BigNumber, BigNumber, BigNumber] & {
      staker: string;
      asset: string;
      amount: BigNumber;
      blockNumber: BigNumber;
      unlockTime: BigNumber;
      withdrawn: BigNumber;
    }
  >;

  "getActiveTranches()"(
    overrides?: CallOverrides
  ): Promise<[BigNumber, BigNumber, BigNumber]>;

  "getActiveTranches(uint256)"(
    _blockNumber: BigNumberish,
    overrides?: CallOverrides
  ): Promise<[BigNumber, BigNumber, BigNumber]>;

  getAllLockRecords(
    overrides?: CallOverrides
  ): Promise<Staking.LockRecordStructOutput[]>;

  getAvailableToClaim(
    _staker: string,
    _chainId: BigNumberish,
    _asset: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  getLockRecords(
    _from: BigNumberish,
    _to: BigNumberish,
    overrides?: CallOverrides
  ): Promise<Staking.LockRecordStructOutput[]>;

  getUnlocked(
    _staker: string,
    overrides?: CallOverrides
  ): Promise<
    [BigNumber, BigNumber] & {
      stablecoinUnlocked: BigNumber;
      protocolUnlocked: BigNumber;
    }
  >;

  getUserDepositIds(
    _user: string,
    overrides?: CallOverrides
  ): Promise<BigNumber[]>;

  getUserDepositRecords(
    _user: string,
    overrides?: CallOverrides
  ): Promise<Staking.DepositRecordStructOutput[]>;

  individualStaked(
    arg0: string,
    arg1: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  lock(
    _asset: string,
    _amountToLock: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  locks(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [BigNumber, BigNumber, BigNumber, string] & {
      amountLocked: BigNumber;
      totalAmountStaked: BigNumber;
      blockNumber: BigNumber;
      asset: string;
    }
  >;

  minimumProtocolStake(overrides?: CallOverrides): Promise<BigNumber>;

  minimumStablecoinStake(overrides?: CallOverrides): Promise<BigNumber>;

  nextIdToUnlock(overrides?: CallOverrides): Promise<BigNumber>;

  payInsurance(
    _chainId: BigNumberish,
    _asset: string,
    _amount: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  protocolToken(overrides?: CallOverrides): Promise<string>;

  reward(
    _lockId: BigNumberish,
    _chainId: BigNumberish,
    _asset: string,
    _amount: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  slash(
    _lockId: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  stablecoin(overrides?: CallOverrides): Promise<string>;

  stake(
    _asset: string,
    _amount: BigNumberish,
    _unlockTime: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  totalStaked(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

  unlock(
    _lockIds: BigNumberish[],
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  withdraw(
    _depositIds: BigNumberish[],
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  callStatic: {
    ACTIVE_PERIODS(overrides?: CallOverrides): Promise<BigNumber>;

    PERIOD_LENGTH(overrides?: CallOverrides): Promise<BigNumber>;

    claim(
      _params: Staking.ClaimParamsStruct,
      overrides?: CallOverrides
    ): Promise<void>;

    currentDepositId(overrides?: CallOverrides): Promise<BigNumber>;

    currentLockId(overrides?: CallOverrides): Promise<BigNumber>;

    deposits(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [string, string, BigNumber, BigNumber, BigNumber, BigNumber] & {
        staker: string;
        asset: string;
        amount: BigNumber;
        blockNumber: BigNumber;
        unlockTime: BigNumber;
        withdrawn: BigNumber;
      }
    >;

    "getActiveTranches()"(
      overrides?: CallOverrides
    ): Promise<[BigNumber, BigNumber, BigNumber]>;

    "getActiveTranches(uint256)"(
      _blockNumber: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber, BigNumber, BigNumber]>;

    getAllLockRecords(
      overrides?: CallOverrides
    ): Promise<Staking.LockRecordStructOutput[]>;

    getAvailableToClaim(
      _staker: string,
      _chainId: BigNumberish,
      _asset: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getLockRecords(
      _from: BigNumberish,
      _to: BigNumberish,
      overrides?: CallOverrides
    ): Promise<Staking.LockRecordStructOutput[]>;

    getUnlocked(
      _staker: string,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber] & {
        stablecoinUnlocked: BigNumber;
        protocolUnlocked: BigNumber;
      }
    >;

    getUserDepositIds(
      _user: string,
      overrides?: CallOverrides
    ): Promise<BigNumber[]>;

    getUserDepositRecords(
      _user: string,
      overrides?: CallOverrides
    ): Promise<Staking.DepositRecordStructOutput[]>;

    individualStaked(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    lock(
      _asset: string,
      _amountToLock: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    locks(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, BigNumber, string] & {
        amountLocked: BigNumber;
        totalAmountStaked: BigNumber;
        blockNumber: BigNumber;
        asset: string;
      }
    >;

    minimumProtocolStake(overrides?: CallOverrides): Promise<BigNumber>;

    minimumStablecoinStake(overrides?: CallOverrides): Promise<BigNumber>;

    nextIdToUnlock(overrides?: CallOverrides): Promise<BigNumber>;

    payInsurance(
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    protocolToken(overrides?: CallOverrides): Promise<string>;

    reward(
      _lockId: BigNumberish,
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    slash(_lockId: BigNumberish, overrides?: CallOverrides): Promise<void>;

    stablecoin(overrides?: CallOverrides): Promise<string>;

    stake(
      _asset: string,
      _amount: BigNumberish,
      _unlockTime: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    totalStaked(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

    unlock(_lockIds: BigNumberish[], overrides?: CallOverrides): Promise<void>;

    withdraw(
      _depositIds: BigNumberish[],
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    ACTIVE_PERIODS(overrides?: CallOverrides): Promise<BigNumber>;

    PERIOD_LENGTH(overrides?: CallOverrides): Promise<BigNumber>;

    claim(
      _params: Staking.ClaimParamsStruct,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;

    currentDepositId(overrides?: CallOverrides): Promise<BigNumber>;

    currentLockId(overrides?: CallOverrides): Promise<BigNumber>;

    deposits(arg0: BigNumberish, overrides?: CallOverrides): Promise<BigNumber>;

    "getActiveTranches()"(overrides?: CallOverrides): Promise<BigNumber>;

    "getActiveTranches(uint256)"(
      _blockNumber: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getAllLockRecords(overrides?: CallOverrides): Promise<BigNumber>;

    getAvailableToClaim(
      _staker: string,
      _chainId: BigNumberish,
      _asset: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getLockRecords(
      _from: BigNumberish,
      _to: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getUnlocked(_staker: string, overrides?: CallOverrides): Promise<BigNumber>;

    getUserDepositIds(
      _user: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getUserDepositRecords(
      _user: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    individualStaked(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    lock(
      _asset: string,
      _amountToLock: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    locks(arg0: BigNumberish, overrides?: CallOverrides): Promise<BigNumber>;

    minimumProtocolStake(overrides?: CallOverrides): Promise<BigNumber>;

    minimumStablecoinStake(overrides?: CallOverrides): Promise<BigNumber>;

    nextIdToUnlock(overrides?: CallOverrides): Promise<BigNumber>;

    payInsurance(
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    protocolToken(overrides?: CallOverrides): Promise<BigNumber>;

    reward(
      _lockId: BigNumberish,
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    slash(
      _lockId: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    stablecoin(overrides?: CallOverrides): Promise<BigNumber>;

    stake(
      _asset: string,
      _amount: BigNumberish,
      _unlockTime: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    totalStaked(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

    unlock(
      _lockIds: BigNumberish[],
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    withdraw(
      _depositIds: BigNumberish[],
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    ACTIVE_PERIODS(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    PERIOD_LENGTH(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    claim(
      _params: Staking.ClaimParamsStruct,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    currentDepositId(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    currentLockId(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    deposits(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "getActiveTranches()"(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "getActiveTranches(uint256)"(
      _blockNumber: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getAllLockRecords(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getAvailableToClaim(
      _staker: string,
      _chainId: BigNumberish,
      _asset: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getLockRecords(
      _from: BigNumberish,
      _to: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getUnlocked(
      _staker: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getUserDepositIds(
      _user: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getUserDepositRecords(
      _user: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    individualStaked(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    lock(
      _asset: string,
      _amountToLock: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    locks(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    minimumProtocolStake(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    minimumStablecoinStake(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    nextIdToUnlock(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    payInsurance(
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    protocolToken(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    reward(
      _lockId: BigNumberish,
      _chainId: BigNumberish,
      _asset: string,
      _amount: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    slash(
      _lockId: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    stablecoin(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    stake(
      _asset: string,
      _amount: BigNumberish,
      _unlockTime: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    totalStaked(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    unlock(
      _lockIds: BigNumberish[],
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    withdraw(
      _depositIds: BigNumberish[],
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;
  };
}
