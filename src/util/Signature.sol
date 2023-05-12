// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity ^0.8.19;

import "../StateUpdateLibrary.sol";
import "@openzeppelin/utils/Strings.sol";

contract Signature {
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(address _participatingInterface) {
        string memory domain = string(
            abi.encodePacked("TXA-", Strings.toHexString(_participatingInterface), Strings.toString(block.chainid))
        );
        DOMAIN_SEPARATOR = keccak256(abi.encodePacked(domain));
    }

    bytes32 public constant STATEUPDATE_TYPEHASH = keccak256(
        abi.encodePacked(
            "StateUpdate(uint8 typeIdentifier,uint256 sequenceId,address participatingInterface,bytes structData)"
        )
    );
    bytes32 public constant SIGNEDSTATEUPDATE_TYPEHASH = keccak256(
        abi.encodePacked(
            "SignedStateUpdate(StateUpdate stateUpdate,uint8 v,bytes32 r,bytes32 s)",
            "StateUpdate(uint8 typeIdentifier,uint256 sequenceId,address participatingInterface,bytes structData)"
        )
    );

    bytes32 public constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "Order(Product product,bool side,uint256 size,uint256 price)",
            "Product(address assetA,uint256 chainIdA,address assetB,uint256 chainIdB)"
        )
    );

    bytes32 public constant PRODUCT_TYPEHASH =
        keccak256(abi.encodePacked("Product(address assetA,uint256 chainIdA,address assetB,uint256 chainIdB)"));

    function hashStateUpdate(StateUpdateLibrary.StateUpdate memory _stateUpdate) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                STATEUPDATE_TYPEHASH,
                _stateUpdate.typeIdentifier,
                _stateUpdate.sequenceId,
                _stateUpdate.participatingInterface,
                _stateUpdate.structData
            )
        );
    }

    function typeHashStateUpdate(StateUpdateLibrary.StateUpdate memory _stateUpdate) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStateUpdate(_stateUpdate)));
    }

    function typeHashOrder(StateUpdateLibrary.Order memory _order) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashOrder(_order)));
    }

    function hashOrder(StateUpdateLibrary.Order memory _order) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(ORDER_TYPEHASH, hashProduct(_order.product), _order.side, _order.size, _order.price));
    }

    function hashProduct(StateUpdateLibrary.Product memory _product) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(PRODUCT_TYPEHASH, _product.assetA, _product.chainIdA, _product.assetB, _product.chainIdB)
        );
    }
}
