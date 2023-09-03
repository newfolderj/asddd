/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Portal, PortalInterface } from "../Portal";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_participatingInterface",
        type: "address",
      },
      {
        internalType: "address",
        name: "_manager",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "CALLER_NOT_ROLLUP",
    type: "error",
  },
  {
    inputs: [],
    name: "INSUFFICIENT_BALANCE_OBLIGATION",
    type: "error",
  },
  {
    inputs: [],
    name: "INSUFFICIENT_BALANCE_TOKEN",
    type: "error",
  },
  {
    inputs: [],
    name: "INSUFFICIENT_BALANCE_WITHDRAW",
    type: "error",
  },
  {
    inputs: [],
    name: "TOKEN_TRANSFER_FAILED_WITHDRAW",
    type: "error",
  },
  {
    inputs: [],
    name: "TRANSFER_FAILED_WITHDRAW",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "wallet",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "Id",
        name: "chainSequenceId",
        type: "uint256",
      },
    ],
    name: "Deposit",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "wallet",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "participatingInterface",
        type: "address",
      },
      {
        indexed: false,
        internalType: "Id",
        name: "chainSequenceId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "bytes32",
        name: "utxo",
        type: "bytes32",
      },
    ],
    name: "DepositUtxo",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [],
    name: "DepositsPaused",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [],
    name: "DepositsResumed",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "asset",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "RejectedDeposit",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "SettlementProcessed",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "Id",
        name: "chainSequenceId",
        type: "uint256",
      },
    ],
    name: "SettlementRequested",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "wallet",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
    ],
    name: "Withdraw",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "wallet",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
    ],
    name: "WithdrawRejectedDeposit",
    type: "event",
  },
  {
    inputs: [],
    name: "chainSequenceId",
    outputs: [
      {
        internalType: "Id",
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
        name: "",
        type: "address",
      },
    ],
    name: "collateralized",
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
    name: "depositNativeAsset",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_token",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "depositToken",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    name: "deposits",
    outputs: [
      {
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        internalType: "address",
        name: "asset",
        type: "address",
      },
      {
        internalType: "address",
        name: "participatingInterface",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "Id",
        name: "chainSequenceId",
        type: "uint256",
      },
      {
        internalType: "Id",
        name: "chainId",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "depositsPaused",
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
        internalType: "address",
        name: "_trader",
        type: "address",
      },
      {
        internalType: "address",
        name: "_token",
        type: "address",
      },
    ],
    name: "getAvailableBalance",
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
    name: "pauseDeposits",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32[]",
        name: "_depositHashes",
        type: "bytes32[]",
      },
    ],
    name: "rejectDeposits",
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
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "rejected",
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
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    name: "rejectedDeposits",
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
        internalType: "address",
        name: "_token",
        type: "address",
      },
    ],
    name: "requestSettlement",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "resumeDeposits",
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
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "settled",
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
        internalType: "Id",
        name: "",
        type: "uint256",
      },
    ],
    name: "settlementRequests",
    outputs: [
      {
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        internalType: "address",
        name: "asset",
        type: "address",
      },
      {
        internalType: "address",
        name: "participatingInterface",
        type: "address",
      },
      {
        internalType: "Id",
        name: "chainSequenceId",
        type: "uint256",
      },
      {
        internalType: "Id",
        name: "chainId",
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
        name: "_amount",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "_token",
        type: "address",
      },
    ],
    name: "withdraw",
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
      {
        internalType: "address",
        name: "_token",
        type: "address",
      },
    ],
    name: "withdrawRejected",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            internalType: "address",
            name: "recipient",
            type: "address",
          },
          {
            internalType: "address",
            name: "asset",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "amount",
            type: "uint256",
          },
        ],
        internalType: "struct IPortal.Obligation[]",
        name: "obligations",
        type: "tuple[]",
      },
    ],
    name: "writeObligations",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60c0604052600080556001805460ff191690553480156200001f57600080fd5b506040516200239c3803806200239c833981016040819052620000429162000077565b6001600160a01b039182166080521660a052620000af565b80516001600160a01b03811681146200007257600080fd5b919050565b600080604083850312156200008b57600080fd5b62000096836200005a565b9150620000a6602084016200005a565b90509250929050565b60805160a051612273620001296000396000818161060d0152818161073e0152818161083101528181610b4f01528181610c3e01528181610f540152818161112501528181611546015261166501526000818161090c01528181610a9501528181610d2501528181610eae015261102e01526122736000f3fe6080604052600436106101285760003560e01c806361060794116100a5578063b2838a7311610074578063c30bc63411610059578063c30bc6341461041a578063d20970371461043a578063d615de381461047257600080fd5b8063b2838a73146103e4578063b43f18731461040457600080fd5b806361060794146102e457806365b399681461030457806398e1489f1461033c5780639ca0ac38146103cf57600080fd5b80633d4dff7b116100fc57806358bd094f116100e157806358bd094f1461026f5780635c25a5b71461028f57806360da3e83146102ca57600080fd5b80633d4dff7b1461018c57806346295e471461022f57600080fd5b8062f714ce1461012d578063021919801461014f5780631587e55814610164578063338b5dea1461016c575b600080fd5b34801561013957600080fd5b5061014d610148366004611f4d565b610492565b005b34801561015b57600080fd5b5061014d61060b565b61014d6106ff565b34801561017857600080fd5b5061014d610187366004611f7d565b610b07565b34801561019857600080fd5b506101ec6101a7366004611fa9565b60026020819052600091825260409091208054600182015492820154600383015460048401546005909401546001600160a01b03938416958416949390921692909186565b604080516001600160a01b039788168152958716602087015293909516928401929092526060830152608082015260a081019190915260c0015b60405180910390f35b34801561023b57600080fd5b5061025f61024a366004611fa9565b60036020526000908152604090205460ff1681565b6040519015158152602001610226565b34801561027b57600080fd5b5061014d61028a366004611fc2565b610f1c565b34801561029b57600080fd5b506102bc6102aa366004611fc2565b60056020526000908152604090205481565b604051908152602001610226565b3480156102d657600080fd5b5060015461025f9060ff1681565b3480156102f057600080fd5b5061014d6102ff366004611fe6565b611123565b34801561031057600080fd5b506102bc61031f36600461205b565b600660209081526000928352604080842090915290825290205481565b34801561034857600080fd5b50610396610357366004611fa9565b6004602081905260009182526040909120805460018201546002830154600384015493909401546001600160a01b039283169491831693919092169185565b604080516001600160a01b039687168152948616602086015292909416918301919091526060820152608081019190915260a001610226565b3480156103db57600080fd5b5061014d611544565b3480156103f057600080fd5b506102bc6103ff36600461205b565b611636565b34801561041057600080fd5b506102bc60005481565b34801561042657600080fd5b5061014d610435366004612089565b611663565b34801561044657600080fd5b506102bc61045536600461205b565b600760209081526000928352604080842090915290825290205481565b34801561047e57600080fd5b5061014d61048d366004611f4d565b611a38565b3360009081526006602090815260408083206001600160a01b03851684529091529020548211156104ef576040517f655723cd00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b3360009081526006602090815260408083206001600160a01b0385168085529252909120805484900390556105a657604051600090339084908381818185875af1925050503d8060008114610560576040519150601f19603f3d011682016040523d82523d6000602084013e610565565b606091505b50509050806105a0576040517f22a5937f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b506105ba565b6105ba6001600160a01b0382163384611ba9565b60408051338152602081018490526001600160a01b038316918101919091527f56c54ba9bd38d8fd62012e42c7ee564519b09763c426d331b3661b537ead19b2906060015b60405180910390a15050565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663f851a4406040518163ffffffff1660e01b8152600401602060405180830381865afa158015610669573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061068d91906120ec565b6001600160a01b0316336001600160a01b0316146106aa57600080fd5b600180547fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0016811790556040517fdeeb69430b7153361c25d630947115165636e6a723fa8daea4b0de34b324745990600090a1565b60015460ff161561070f57600080fd5b6040517fd82e66fa000000000000000000000000000000000000000000000000000000008152600060048201527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169063d82e66fa90602401602060405180830381865afa15801561078d573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107b19190612109565b6108025760405162461bcd60e51b815260206004820152601d60248201527f4e6174697665206173736574206973206e6f7420737570706f7274656400000060448201526064015b60405180910390fd5b6040517f69adf0f0000000000000000000000000000000000000000000000000000000008152600060048201527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316906369adf0f090602401602060405180830381865afa158015610880573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108a4919061212b565b3410156108f35760405162461bcd60e51b815260206004820152601560248201527f42656c6f77206d696e696d756d206465706f736974000000000000000000000060448201526064016107f9565b6040805160c081018252338152600060208083018290527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031683850152346060840152815460808401524660a08401529251919290916109ab91849101600060c0820190506001600160a01b0380845116835280602085015116602084015280604085015116604084015250606083015160608301526080830151608083015260a083015160a083015292915050565b60408051808303601f19018152828252805160209182012060008181526002808452848220885181547fffffffffffffffffffffffff00000000000000000000000000000000000000009081166001600160a01b039283161783558a87015160018401805483169184169190911790558a8801519383018054909116938216939093179092556060808a015160038301556080808b0151600484015560a0808c01516005948501558580529287527f05b8ccbb9d4d8fb16ea74ce3c29a41f1b461fbdaff4714a0d9a8eb05499746bc8054349081019091558554338b52978a0152968801939093527f0000000000000000000000000000000000000000000000000000000000000000909116918601919091529284019190915290820181905291507fc88756dd73e6bb8b762d9037ebc78074164c9f9ae658c709b6137d2fea83f7f89060c00160405180910390a16000546001016000555050565b60015460ff1615610b1757600080fd5b6040517fd82e66fa0000000000000000000000000000000000000000000000000000000081526001600160a01b0383811660048301527f0000000000000000000000000000000000000000000000000000000000000000169063d82e66fa90602401602060405180830381865afa158015610b96573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610bba9190612109565b610c065760405162461bcd60e51b815260206004820152601660248201527f4173736574206973206e6f7420737570706f727465640000000000000000000060448201526064016107f9565b6040517f69adf0f00000000000000000000000000000000000000000000000000000000081526001600160a01b0383811660048301527f000000000000000000000000000000000000000000000000000000000000000016906369adf0f090602401602060405180830381865afa158015610c85573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610ca9919061212b565b811015610cf85760405162461bcd60e51b815260206004820152601560248201527f42656c6f77206d696e696d756d206465706f736974000000000000000000000060448201526064016107f9565b60006040518060c00160405280336001600160a01b03168152602001846001600160a01b031681526020017f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031681526020018381526020016000548152602001468152509050600081604051602001610dc79190600060c0820190506001600160a01b0380845116835280602085015116602084015280604085015116604084015250606083015160608301526080830151608083015260a083015160a083015292915050565b60408051808303601f19018152918152815160209283012060008181526002808552838220875181547fffffffffffffffffffffffff00000000000000000000000000000000000000009081166001600160a01b0392831617835589880151600184018054831691841691909117905589870151938301805490911693821693909317909255606088015160038201556080880151600482015560a08801516005918201559089168083529452919091208054860190559150610e8c90333086611c52565b60005460408051338152602081018690526001600160a01b03878116828401527f0000000000000000000000000000000000000000000000000000000000000000166060820152608081019290925260a08201839052517fc88756dd73e6bb8b762d9037ebc78074164c9f9ae658c709b6137d2fea83f7f89181900360c00190a160005460010160005550505050565b6040517fd82e66fa0000000000000000000000000000000000000000000000000000000081526001600160a01b0382811660048301527f0000000000000000000000000000000000000000000000000000000000000000169063d82e66fa90602401602060405180830381865afa158015610f9b573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610fbf9190612109565b61100b5760405162461bcd60e51b815260206004820152601660248201527f4173736574206973206e6f7420737570706f727465640000000000000000000060448201526064016107f9565b6040805160a081018252338082526001600160a01b0384811660208085018281527f00000000000000000000000000000000000000000000000000000000000000008416868801908152600080546060808a018281524660808c0190815292845260048088528c85209b518c54908b167fffffffffffffffffffffffff0000000000000000000000000000000000000000918216178d55965160018d018054918c16918916919091179055945160028c01805491909a169616959095179097559251600389015591519601959095559354855193845293830152928101919091527f6667b10209a19e78c037ae773e4b5fc3128718495569a6b1fd04f3b3fe6de897910160405180910390a160005460010160005550565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663f7260d3e6040518163ffffffff1660e01b8152600401602060405180830381865afa158015611181573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906111a591906120ec565b6001600160a01b0316336001600160a01b03161461122b5760405162461bcd60e51b815260206004820152602160248201527f4f6e6c792072656365697665722063616e2072656a656374206465706f73697460448201527f730000000000000000000000000000000000000000000000000000000000000060648201526084016107f9565b60005b8181101561153f5760006002600085858581811061124e5761124e612144565b602090810292909201358352508181019290925260409081016000908120825160c08101845281546001600160a01b03908116825260018301548116958201959095526002820154909416928401929092526003820154606084018190526004830154608085015260059092015460a084015291925090036113125760405162461bcd60e51b815260206004820152601b60248201527f4465706f736974206861736820646f6573206e6f74206578697374000000000060448201526064016107f9565b6003600085858581811061132857611328612144565b602090810292909201358352508101919091526040016000205460ff16156113925760405162461bcd60e51b815260206004820152601860248201527f4465706f73697420616c72656164792072656a6563746564000000000000000060448201526064016107f9565b60608101516020808301516001600160a01b031660009081526005909152604090205410156114035760405162461bcd60e51b815260206004820152601460248201527f496e73756666696369656e742062616c616e636500000000000000000000000060448201526064016107f9565b606081015181516001600160a01b03908116600090815260076020908152604080832082870151909416835292905290812080549091906114459084906121a2565b909155505060608101516020808301516001600160a01b03166000908152600590915260408120805490919061147c9084906121b5565b90915550600190506003600086868681811061149a5761149a612144565b90506020020135815260200190815260200160002060006101000a81548160ff0219169083151502179055507f2e4cac172b16d29f62fbed4cafbf9d4e3919d6638871542e136a6ed09ff966c2816000015182602001518360600151604051611524939291906001600160a01b039384168152919092166020820152604081019190915260600190565b60405180910390a15080611537816121c8565b91505061122e565b505050565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663f851a4406040518163ffffffff1660e01b8152600401602060405180830381865afa1580156115a2573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906115c691906120ec565b6001600160a01b0316336001600160a01b0316146115e357600080fd5b600180547fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff001690556040517f1ba9bbaac2497ed7a7c42445bdab75d210756e8147f5dc1796858f05d17d04b190600090a1565b6001600160a01b038083166000908152600660209081526040808320938516835292905220545b92915050565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663f7260d3e6040518163ffffffff1660e01b8152600401602060405180830381865afa1580156116c1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906116e591906120ec565b6001600160a01b0316336001600160a01b03161461176b5760405162461bcd60e51b815260206004820152602360248201527f4f6e6c792072656365697665722063616e207772697465206f626c696761746960448201527f6f6e73000000000000000000000000000000000000000000000000000000000060648201526084016107f9565b60005b8181101561153f5782828281811061178857611788612144565b90506060020160400135600560008585858181106117a8576117a8612144565b90506060020160200160208101906117c09190611fc2565b6001600160a01b03166001600160a01b03168152602001908152602001600020541015611819576040517f5c13b60f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b82828281811061182b5761182b612144565b905060600201604001356005600085858581811061184b5761184b612144565b90506060020160200160208101906118639190611fc2565b6001600160a01b03166001600160a01b03168152602001908152602001600020600082825461189291906121b5565b9091555083905082828181106118aa576118aa612144565b90506060020160400135600660008585858181106118ca576118ca612144565b6118e09260206060909202019081019150611fc2565b6001600160a01b03166001600160a01b03168152602001908152602001600020600085858581811061191457611914612144565b905060600201602001602081019061192c9190611fc2565b6001600160a01b03166001600160a01b03168152602001908152602001600020600082825461195b91906121a2565b909155507f5323a9af3e86172577f2f4c75b43d40068e033787d2c215e0f6bbaab836d79dc905083838381811061199457611994612144565b6119aa9260206060909202019081019150611fc2565b8484848181106119bc576119bc612144565b90506060020160200160208101906119d49190611fc2565b8585858181106119e6576119e6612144565b90506060020160400135604051611a1e939291906001600160a01b039384168152919092166020820152604081019190915260600190565b60405180910390a180611a30816121c8565b91505061176e565b3360009081526007602090815260408083206001600160a01b0385168452909152902054821115611a95576040517f655723cd00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b3360009081526007602090815260408083206001600160a01b038516808552925290912080548490039055611b4c57604051600090339084908381818185875af1925050503d8060008114611b06576040519150601f19603f3d011682016040523d82523d6000602084013e611b0b565b606091505b5050905080611b46576040517f22a5937f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b50611b60565b611b606001600160a01b0382163384611ba9565b60408051338152602081018490526001600160a01b038316918101919091527f44b9cbe1ac31a48c52c024841b84bb82452debc1d52f70c6e4c12b871687b4e6906060016105ff565b6040516001600160a01b03831660248201526044810182905261153f9084907fa9059cbb00000000000000000000000000000000000000000000000000000000906064015b60408051601f198184030181529190526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff0000000000000000000000000000000000000000000000000000000090931692909217909152611ca9565b6040516001600160a01b0380851660248301528316604482015260648101829052611ca39085907f23b872dd0000000000000000000000000000000000000000000000000000000090608401611bee565b50505050565b6000611cfe826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c6564815250856001600160a01b0316611d8e9092919063ffffffff16565b80519091501561153f5780806020019051810190611d1c9190612109565b61153f5760405162461bcd60e51b815260206004820152602a60248201527f5361666545524332303a204552433230206f7065726174696f6e20646964206e60448201527f6f7420737563636565640000000000000000000000000000000000000000000060648201526084016107f9565b6060611d9d8484600085611da5565b949350505050565b606082471015611e1d5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a20696e73756666696369656e742062616c616e636520666f60448201527f722063616c6c000000000000000000000000000000000000000000000000000060648201526084016107f9565b600080866001600160a01b03168587604051611e399190612224565b60006040518083038185875af1925050503d8060008114611e76576040519150601f19603f3d011682016040523d82523d6000602084013e611e7b565b606091505b5091509150611e8c87838387611e97565b979650505050505050565b60608315611f06578251600003611eff576001600160a01b0385163b611eff5760405162461bcd60e51b815260206004820152601d60248201527f416464726573733a2063616c6c20746f206e6f6e2d636f6e747261637400000060448201526064016107f9565b5081611d9d565b611d9d8383815115611f1b5781518083602001fd5b8060405162461bcd60e51b81526004016107f99190612240565b6001600160a01b0381168114611f4a57600080fd5b50565b60008060408385031215611f6057600080fd5b823591506020830135611f7281611f35565b809150509250929050565b60008060408385031215611f9057600080fd5b8235611f9b81611f35565b946020939093013593505050565b600060208284031215611fbb57600080fd5b5035919050565b600060208284031215611fd457600080fd5b8135611fdf81611f35565b9392505050565b60008060208385031215611ff957600080fd5b823567ffffffffffffffff8082111561201157600080fd5b818501915085601f83011261202557600080fd5b81358181111561203457600080fd5b8660208260051b850101111561204957600080fd5b60209290920196919550909350505050565b6000806040838503121561206e57600080fd5b823561207981611f35565b91506020830135611f7281611f35565b6000806020838503121561209c57600080fd5b823567ffffffffffffffff808211156120b457600080fd5b818501915085601f8301126120c857600080fd5b8135818111156120d757600080fd5b86602060608302850101111561204957600080fd5b6000602082840312156120fe57600080fd5b8151611fdf81611f35565b60006020828403121561211b57600080fd5b81518015158114611fdf57600080fd5b60006020828403121561213d57600080fd5b5051919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b8082018082111561165d5761165d612173565b8181038181111561165d5761165d612173565b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82036121f9576121f9612173565b5060010190565b60005b8381101561221b578181015183820152602001612203565b50506000910152565b60008251612236818460208701612200565b9190910192915050565b602081526000825180602084015261225f816040850160208701612200565b601f01601f1916919091016040019291505056";

type PortalConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: PortalConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class Portal__factory extends ContractFactory {
  constructor(...args: PortalConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _participatingInterface: string,
    _manager: string,
    overrides?: Overrides & { from?: string }
  ): Promise<Portal> {
    return super.deploy(
      _participatingInterface,
      _manager,
      overrides || {}
    ) as Promise<Portal>;
  }
  override getDeployTransaction(
    _participatingInterface: string,
    _manager: string,
    overrides?: Overrides & { from?: string }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _participatingInterface,
      _manager,
      overrides || {}
    );
  }
  override attach(address: string): Portal {
    return super.attach(address) as Portal;
  }
  override connect(signer: Signer): Portal__factory {
    return super.connect(signer) as Portal__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): PortalInterface {
    return new utils.Interface(_abi) as PortalInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Portal {
    return new Contract(address, _abi, signerOrProvider) as Portal;
  }
}
