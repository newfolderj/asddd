/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  BigNumberish,
  Overrides,
} from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Oracle, OracleInterface } from "../Oracle";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_admin",
        type: "address",
      },
      {
        internalType: "address",
        name: "_manager",
        type: "address",
      },
      {
        internalType: "address",
        name: "_protocolToken",
        type: "address",
      },
      {
        internalType: "address",
        name: "_stablecoinAssetChain",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_stablecoinAssetChainId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_protocolTokenPrice",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "PRICE_COOLDOWN",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "PRICE_EXPIRY",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "admin",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_chainId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "_asset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "getStablecoinValue",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_reporter",
        type: "address",
      },
    ],
    name: "grantReporter",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_chainId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "_asset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_price",
        type: "uint256",
      },
    ],
    name: "initializePrice",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "isReporter",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "lastReport",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "latestPrice",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "manager",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_chainId",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "_asset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_price",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "_modulo",
        type: "bool",
      },
    ],
    name: "report",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "chainId",
            type: "uint256",
          },
          {
            internalType: "address",
            name: "asset",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "price",
            type: "uint256",
          },
        ],
        internalType: "struct Oracle.PriceReport[]",
        name: "_prices",
        type: "tuple[]",
      },
    ],
    name: "reportPrices",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_reporter",
        type: "address",
      },
    ],
    name: "revokeReporter",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "stablecoinToProtocol",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "tokenPrecision",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60e06040523480156200001157600080fd5b506040516200147838038062001478833981016040819052620000349162000161565b600380546001600160a01b038089166001600160a01b031992831617909255600480548884169216919091178155858216608081905291851660a05260c08490526040805163313ce56760e01b8152905163313ce567928281019260209291908290030181865afa158015620000ae573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620000d49190620001d0565b4660008181526002602090815260408083206001600160a01b0399909916808452988252808320805460ff191660ff96909616959095179094558282526001815283822088835281528382204390559181528082528281209681529590529093209290925550620001fc92505050565b80516001600160a01b03811681146200015c57600080fd5b919050565b60008060008060008060c087890312156200017b57600080fd5b620001868762000144565b9550620001966020880162000144565b9450620001a66040880162000144565b9350620001b66060880162000144565b92506080870151915060a087015190509295509295509295565b600060208284031215620001e357600080fd5b815160ff81168114620001f557600080fd5b9392505050565b60805160a05160c0516112456200023360003960006106d601526000610700015260008181610a9d0152610b6301526112456000f3fe608060405234801561001057600080fd5b50600436106100f55760003560e01c80636e4a22ed11610097578063ce04b50211610066578063ce04b50214610264578063d86d30a41461028c578063ee39043c1461029f578063f851a440146102b257600080fd5b80636e4a22ed146102205780638cdcc95514610233578063a04c2e1514610246578063b61bf1a51461025957600080fd5b80633d60c79c116100d35780633d60c79c1461015a578063481c6a75146101705780635a0b25b1146101b55780635e3f6c8f146101f557600080fd5b8063044ad7be146100fa5780630c32e02f1461013257806333a9cd0214610147575b600080fd5b61011d610108366004610e8b565b60056020526000908152604090205460ff1681565b60405190151581526020015b60405180910390f35b610145610140366004610ea6565b6102d2565b005b610145610155366004610ef3565b610644565b610162604b81565b604051908152602001610129565b6004546101909073ffffffffffffffffffffffffffffffffffffffff1681565b60405173ffffffffffffffffffffffffffffffffffffffff9091168152602001610129565b6101e36101c3366004610f68565b600260209081526000928352604080842090915290825290205460ff1681565b60405160ff9091168152602001610129565b610162610203366004610f68565b600160209081526000928352604080842090915290825290205481565b61016261022e366004610f94565b6106d2565b610145610241366004610e8b565b6108d7565b610145610254366004610e8b565b6109a4565b610162633b9ac9ff81565b610162610272366004610f68565b600060208181529281526040808220909352908152205481565b61016261029a366004610fc9565b610a74565b6101456102ad366004610f94565b610bb7565b6003546101909073ffffffffffffffffffffffffffffffffffffffff1681565b3360009081526005602052604090205460ff16610350576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152600d60248201527f4f6e6c79207265706f727465720000000000000000000000000000000000000060448201526064015b60405180910390fd5b600084815260016020908152604080832073ffffffffffffffffffffffffffffffffffffffff8716845290915281205490036103e8576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601b60248201527f4173736574207072696365206e6f7420696e697469616c697a656400000000006044820152606401610347565b600084815260016020908152604080832073ffffffffffffffffffffffffffffffffffffffff8716845290915290205461042490604b90611011565b4310156104b2576040517f08c379a0000000000000000000000000000000000000000000000000000000008152602060048201526024808201527f507269636520636f6f6c646f776e20706572696f6420686173206e6f7420706160448201527f73736564000000000000000000000000000000000000000000000000000000006064820152608401610347565b60008481526020818152604080832073ffffffffffffffffffffffffffffffffffffffff8716845290915281205490670de0b6b3a76400006104fc83670bcbce7f1b15000061102a565b6105069190611041565b90506000670de0b6b3a764000061052584670ff59ee833b3000061102a565b61052f9190611041565b905083801561053d57508085115b15610546578094505b83801561055257508185105b1561055b578194505b8085118061056857508185105b156105f5576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602560248201527f52656a656374207072696365206368616e676573206f66206d6f72652074686160448201527f6e203135250000000000000000000000000000000000000000000000000000006064820152608401610347565b505050600084815260016020908152604080832073ffffffffffffffffffffffffffffffffffffffff909616808452958252808320439055958252818152858220948252939093525091902055565b60005b818110156106cd576106bb8383838181106106645761066461107c565b905060600201600001358484848181106106805761068061107c565b90506060020160200160208101906106989190610e8b565b8585858181106106aa576106aa61107c565b9050606002016040013560016102d2565b806106c5816110ab565b915050610647565b505050565b60007f00000000000000000000000000000000000000000000000000000000000000008414801561074e57507f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16145b1561075a5750806108d0565b600084815260016020908152604080832073ffffffffffffffffffffffffffffffffffffffff8716845290915290205461079990633b9ac9ff90611011565b4310610801576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601b60248201527f507269636520666f7220617373657420686173206578706972656400000000006044820152606401610347565b60008481526020818152604080832073ffffffffffffffffffffffffffffffffffffffff871680855290835281842054888552600284528285209185529252822054909160ff90911690670de0b6b3a764000061085e848761102a565b6108689190611041565b9050600682111561089d5761087e6006836110e3565b61088990600a611216565b6108939082611041565b93505050506108d0565b60068210156108c6576108b18260066110e3565b6108bc90600a611216565b610893908261102a565b92506108d0915050565b9392505050565b60035473ffffffffffffffffffffffffffffffffffffffff163314610958576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152600a60248201527f4f6e6c792061646d696e000000000000000000000000000000000000000000006044820152606401610347565b73ffffffffffffffffffffffffffffffffffffffff16600090815260056020526040902080547fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00169055565b60035473ffffffffffffffffffffffffffffffffffffffff163314610a25576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152600a60248201527f4f6e6c792061646d696e000000000000000000000000000000000000000000006044820152606401610347565b73ffffffffffffffffffffffffffffffffffffffff16600090815260056020526040902080547fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00166001179055565b46600090815260016020908152604080832073ffffffffffffffffffffffffffffffffffffffff7f0000000000000000000000000000000000000000000000000000000000000000168452909152812054610ad490633b9ac9ff90611011565b4310610b3c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601b60248201527f507269636520666f7220617373657420686173206578706972656400000000006044820152606401610347565b4660009081526020818152604080832073ffffffffffffffffffffffffffffffffffffffff7f000000000000000000000000000000000000000000000000000000000000000016845290915290205480610b9e84670de0b6b3a764000061102a565b610ba89190611041565b6108d09064e8d4a5100061102a565b3360009081526005602052604090205460ff16610c30576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152600d60248201527f4f6e6c79207265706f72746572000000000000000000000000000000000000006044820152606401610347565b600480546040517fd3a112b700000000000000000000000000000000000000000000000000000000815291820185905273ffffffffffffffffffffffffffffffffffffffff848116602484015260009291169063d3a112b790604401602060405180830381865afa158015610ca9573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610ccd9190611222565b90508060ff16600003610d3c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601160248201527f556e737570706f727465642061737365740000000000000000000000000000006044820152606401610347565b60008481526020818152604080832073ffffffffffffffffffffffffffffffffffffffff871684529091529020548015610dd2576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601360248201527f416c726561647920696e697469616c697a6564000000000000000000000000006044820152606401610347565b50600084815260026020908152604080832073ffffffffffffffffffffffffffffffffffffffff909616808452958252808320805460ff9095167fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00909516949094179093558582526001815282822085835281528282204390559481528085528181209381529290935291902055565b803573ffffffffffffffffffffffffffffffffffffffff81168114610e8657600080fd5b919050565b600060208284031215610e9d57600080fd5b6108d082610e62565b60008060008060808587031215610ebc57600080fd5b84359350610ecc60208601610e62565b92506040850135915060608501358015158114610ee857600080fd5b939692955090935050565b60008060208385031215610f0657600080fd5b823567ffffffffffffffff80821115610f1e57600080fd5b818501915085601f830112610f3257600080fd5b813581811115610f4157600080fd5b866020606083028501011115610f5657600080fd5b60209290920196919550909350505050565b60008060408385031215610f7b57600080fd5b82359150610f8b60208401610e62565b90509250929050565b600080600060608486031215610fa957600080fd5b83359250610fb960208501610e62565b9150604084013590509250925092565b600060208284031215610fdb57600080fd5b5035919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b8082018082111561102457611024610fe2565b92915050565b808202811582820484141761102457611024610fe2565b600082611077577f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b500490565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82036110dc576110dc610fe2565b5060010190565b8181038181111561102457611024610fe2565b600181815b8085111561114f57817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0482111561113557611135610fe2565b8085161561114257918102915b93841c93908002906110fb565b509250929050565b60008261116657506001611024565b8161117357506000611024565b81600181146111895760028114611193576111af565b6001915050611024565b60ff8411156111a4576111a4610fe2565b50506001821b611024565b5060208310610133831016604e8410600b84101617156111d2575081810a611024565b6111dc83836110f6565b807fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0482111561120e5761120e610fe2565b029392505050565b60006108d08383611157565b60006020828403121561123457600080fd5b815160ff811681146108d057600080fd";

type OracleConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: OracleConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class Oracle__factory extends ContractFactory {
  constructor(...args: OracleConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _admin: string,
    _manager: string,
    _protocolToken: string,
    _stablecoinAssetChain: string,
    _stablecoinAssetChainId: BigNumberish,
    _protocolTokenPrice: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<Oracle> {
    return super.deploy(
      _admin,
      _manager,
      _protocolToken,
      _stablecoinAssetChain,
      _stablecoinAssetChainId,
      _protocolTokenPrice,
      overrides || {}
    ) as Promise<Oracle>;
  }
  override getDeployTransaction(
    _admin: string,
    _manager: string,
    _protocolToken: string,
    _stablecoinAssetChain: string,
    _stablecoinAssetChainId: BigNumberish,
    _protocolTokenPrice: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _admin,
      _manager,
      _protocolToken,
      _stablecoinAssetChain,
      _stablecoinAssetChainId,
      _protocolTokenPrice,
      overrides || {}
    );
  }
  override attach(address: string): Oracle {
    return super.attach(address) as Oracle;
  }
  override connect(signer: Signer): Oracle__factory {
    return super.connect(signer) as Oracle__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): OracleInterface {
    return new utils.Interface(_abi) as OracleInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Oracle {
    return new Contract(address, _abi, signerOrProvider) as Oracle;
  }
}
