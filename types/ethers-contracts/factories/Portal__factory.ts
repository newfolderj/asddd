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
    inputs: [],
    name: "UTXO_ALREADY_CLAIMED",
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
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "deliverer",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "recipient",
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
    name: "ObligationWritten",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "settlementID",
        type: "uint256",
      },
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
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    name: "claimed",
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
    inputs: [
      {
        internalType: "uint256",
        name: "_chainSequenceId",
        type: "uint256",
      },
      {
        internalType: "bytes32",
        name: "_settlementHash",
        type: "bytes32",
      },
    ],
    name: "isValidSettlementRequest",
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
    inputs: [],
    name: "nextRequestId",
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
      {
        internalType: "Id",
        name: "settlementId",
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
  "0x60c06040526000600155600280553480156200001a57600080fd5b50604051620018a9380380620018a98339810160408190526200003d9162000072565b6001600160a01b039182166080521660a052620000aa565b80516001600160a01b03811681146200006d57600080fd5b919050565b600080604083850312156200008657600080fd5b620000918362000055565b9150620000a16020840162000055565b90509250929050565b60805160a0516117a8620001016000396000818161066701528181610a3701528181610e96015261116e01526000818161076b0152818161093b01528181610b3901528181610d850152610f9701526117a86000f3fe6080604052600436106100dc5760003560e01c80636a84a9851161007f578063b2838a7311610059578063b2838a731461032b578063b43f18731461037e578063c30bc63414610394578063cc3c0f06146103b457600080fd5b80636a84a985146102795780637b6d899d1461028f57806398e1489f146102bf57600080fd5b80633d4dff7b116100bb5780633d4dff7b1461012b57806358bd094f146101e65780635c25a5b71461020657806365b399681461024157600080fd5b8062f714ce146100e15780631587e55814610103578063338b5dea1461010b575b600080fd5b3480156100ed57600080fd5b506101016100fc36600461154f565b6103e4565b005b610101610638565b34801561011757600080fd5b5061010161012636600461157f565b6109f2565b34801561013757600080fd5b506101966101463660046115ab565b60006020819052908152604090208054600182015460028301546003840154600485015460059095015473ffffffffffffffffffffffffffffffffffffffff948516959385169490921692909186565b6040805173ffffffffffffffffffffffffffffffffffffffff9788168152958716602087015293909516928401929092526060830152608082015260a081019190915260c0015b60405180910390f35b3480156101f257600080fd5b506101016102013660046115c4565b610e51565b34801561021257600080fd5b506102336102213660046115c4565b60056020526000908152604090205481565b6040519081526020016101dd565b34801561024d57600080fd5b5061023361025c3660046115e8565b600660209081526000928352604080842090915290825290205481565b34801561028557600080fd5b5061023360025481565b34801561029b57600080fd5b506102af6102aa366004611616565b6110d9565b60405190151581526020016101dd565b3480156102cb57600080fd5b506101966102da3660046115ab565b600460208190526000918252604090912080546001820154600283015460038401549484015460059094015473ffffffffffffffffffffffffffffffffffffffff9384169592841694919093169286565b34801561033757600080fd5b506102336103463660046115e8565b73ffffffffffffffffffffffffffffffffffffffff918216600090815260066020908152604080832093909416825291909152205490565b34801561038a57600080fd5b5061023360015481565b3480156103a057600080fd5b506101016103af366004611638565b61116c565b3480156103c057600080fd5b506102af6103cf3660046115ab565b60036020526000908152604090205460ff1681565b33600090815260066020908152604080832073ffffffffffffffffffffffffffffffffffffffff8516845290915290205482111561044e576040517f655723cd00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b33600090815260066020908152604080832073ffffffffffffffffffffffffffffffffffffffff851680855292529091208054849003905561051257604051600090339084908381818185875af1925050503d80600081146104cc576040519150601f19603f3d011682016040523d82523d6000602084013e6104d1565b606091505b505090508061050c576040517f22a5937f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b506105df565b6040517fa9059cbb0000000000000000000000000000000000000000000000000000000081523360048201526024810183905273ffffffffffffffffffffffffffffffffffffffff82169063a9059cbb906044016020604051808303816000875af1158015610585573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906105a991906116ad565b6105df576040517f4b1fdad200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b604080513381526020810184905273ffffffffffffffffffffffffffffffffffffffff83168183015290517f56c54ba9bd38d8fd62012e42c7ee564519b09763c426d331b3661b537ead19b29181900360600190a15050565b6040517fd82e66fa000000000000000000000000000000000000000000000000000000008152600060048201527f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff169063d82e66fa90602401602060405180830381865afa1580156106c3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906106e791906116ad565b610752576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601d60248201527f4e6174697665206173736574206973206e6f7420737570706f7274656400000060448201526064015b60405180910390fd5b6040805160c081018252338152600060208083018290527f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff168385015234606084015260015460808401524660a084015292519192909161082591849101600060c08201905073ffffffffffffffffffffffffffffffffffffffff80845116835280602085015116602084015280604085015116604084015250606083015160608301526080830151608083015260a083015160a083015292915050565b604080518083037fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe001815282825280516020918201206000818152808352838120875181547fffffffffffffffffffffffff000000000000000000000000000000000000000090811673ffffffffffffffffffffffffffffffffffffffff92831617835589860151600180850180548416928516929092179091558a880151600285018054909316908416179091556060808b015160038501556080808c0151600486015560a0808d01516005968701558680529488527f05b8ccbb9d4d8fb16ea74ce3c29a41f1b461fbdaff4714a0d9a8eb05499746bc8054349081019091559254338b52978a0192909252968801939093527f0000000000000000000000000000000000000000000000000000000000000000169486019490945284019190915290820181905291507fc88756dd73e6bb8b762d9037ebc78074164c9f9ae658c709b6137d2fea83f7f89060c00160405180910390a1600154604080513381523460208201526000818301526060810192909252517fd2f8022f659fd9c8c558f30c00fd5ee7038f7cb56da45095c3e0e7d48b3e0c4b9181900360800190a160018054016001555050565b6040517fd82e66fa00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff83811660048301527f0000000000000000000000000000000000000000000000000000000000000000169063d82e66fa90602401602060405180830381865afa158015610a7e573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610aa291906116ad565b610b08576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601660248201527f4173736574206973206e6f7420737570706f72746564000000000000000000006044820152606401610749565b6040805160c080820183523380835273ffffffffffffffffffffffffffffffffffffffff86811660208086019182527f0000000000000000000000000000000000000000000000000000000000000000831686880190815260608088018a81526001546080808b019182524660a0808d019182528d519788019a909a52965188169b86019b909b5292519095169083015292519681019690965290519185019190915251908301529060009060e001604080518083037fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe001815282825280516020918201206000818152808352838120875181547fffffffffffffffffffffffff000000000000000000000000000000000000000090811673ffffffffffffffffffffffffffffffffffffffff9283161783558986015160018401805483169184169190911790558987015160028401805490921690831617905560608901516003830155608089015160048084019190915560a08a0151600593840155908b16808452919094529390208054880190557f23b872dd0000000000000000000000000000000000000000000000000000000084523391840191909152306024840152604483018690529250906323b872dd906064016020604051808303816000875af1158015610cfc573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610d2091906116ad565b610d56576040517f0c103aec00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b600154604080513381526020810186905273ffffffffffffffffffffffffffffffffffffffff878116828401527f0000000000000000000000000000000000000000000000000000000000000000166060820152608081019290925260a08201839052517fc88756dd73e6bb8b762d9037ebc78074164c9f9ae658c709b6137d2fea83f7f89181900360c00190a1600154604080513381526020810186905273ffffffffffffffffffffffffffffffffffffffff8716818301526060810192909252517fd2f8022f659fd9c8c558f30c00fd5ee7038f7cb56da45095c3e0e7d48b3e0c4b9181900360800190a1600180540160015550505050565b6040517fd82e66fa00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff82811660048301527f0000000000000000000000000000000000000000000000000000000000000000169063d82e66fa90602401602060405180830381865afa158015610edd573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610f0191906116ad565b610f67576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601660248201527f4173736574206973206e6f7420737570706f72746564000000000000000000006044820152606401610749565b6040805160c0810182523380825273ffffffffffffffffffffffffffffffffffffffff84811660208085019182527f0000000000000000000000000000000000000000000000000000000000000000831685870190815260018054606088018181524660808a019081526002805460a08c019081526000948552600497889052938c90209a518b54908a167fffffffffffffffffffffffff0000000000000000000000000000000000000000918216178c5597518b86018054918b16918a1691909117905594518a860180549190991697169690961790965594516003880155925191860191909155915160059094019390935554915492517fafecde7e9884314ecb0053b851cb30aa8a21b39357f14d7065601a75ee225601936110bd93929186919093845273ffffffffffffffffffffffffffffffffffffffff928316602085015291166040830152606082015260800190565b60405180910390a1600180540160019081556002540160025550565b60008281526004602090815260408083209051849261114c929101815473ffffffffffffffffffffffffffffffffffffffff90811682526001830154811660208301526002830154166040820152600382015460608201526004820154608082015260059091015460a082015260c00190565b604051602081830303815290604052805190602001201490505b92915050565b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff1663f7260d3e6040518163ffffffff1660e01b8152600401602060405180830381865afa1580156111d7573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906111fb91906116cf565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146112b5576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602360248201527f4f6e6c792072656365697665722063616e207772697465206f626c696761746960448201527f6f6e7300000000000000000000000000000000000000000000000000000000006064820152608401610749565b60005b81811015611525578282828181106112d2576112d26116ec565b90506060020160400135600560008585858181106112f2576112f26116ec565b905060600201602001602081019061130a91906115c4565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054101561137d576040517f5c13b60f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b82828281811061138f5761138f6116ec565b90506060020160400135600560008585858181106113af576113af6116ec565b90506060020160200160208101906113c791906115c4565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254611410919061174a565b909155508390508282818110611428576114286116ec565b9050606002016040013560066000858585818110611448576114486116ec565b61145e92602060609092020190810191506115c4565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008585858181106114ac576114ac6116ec565b90506060020160200160208101906114c491906115c4565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825461150d919061175d565b9091555081905061151d81611770565b9150506112b8565b505050565b73ffffffffffffffffffffffffffffffffffffffff8116811461154c57600080fd5b50565b6000806040838503121561156257600080fd5b8235915060208301356115748161152a565b809150509250929050565b6000806040838503121561159257600080fd5b823561159d8161152a565b946020939093013593505050565b6000602082840312156115bd57600080fd5b5035919050565b6000602082840312156115d657600080fd5b81356115e18161152a565b9392505050565b600080604083850312156115fb57600080fd5b82356116068161152a565b915060208301356115748161152a565b6000806040838503121561162957600080fd5b50508035926020909101359150565b6000806020838503121561164b57600080fd5b823567ffffffffffffffff8082111561166357600080fd5b818501915085601f83011261167757600080fd5b81358181111561168657600080fd5b86602060608302850101111561169b57600080fd5b60209290920196919550909350505050565b6000602082840312156116bf57600080fd5b815180151581146115e157600080fd5b6000602082840312156116e157600080fd5b81516115e18161152a565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b818103818111156111665761116661171b565b808201808211156111665761116661171b565b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82036117a1576117a161171b565b506001019056";

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
