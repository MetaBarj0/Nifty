// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IInitializable } from "../interfaces/proxy/IInitializable.sol";
import { ITransparentUpgradeableProxy } from "../interfaces/proxy/ITransparentUpgradeableProxy.sol";
import { ERC165 } from "../introspection/ERC165.sol";

import { ProxyStorage } from "./ProxyStorage.sol";

// TODO: Ownable2Steps admin and changeImplementation
contract TransparentUpgradeableProxy is ITransparentUpgradeableProxy {
  // bytes32(keccak256("ITransparentUpgradeableProxy.implementation"));
  bytes32 public constant IMPLEMENTATION_SLOT = 0x89cc2b981328df209fd92734b973154b4a0db2c602160538b307a6538510f52c;

  address private immutable admin_;

  constructor(address implementationContract, bytes memory data) {
    require(implementationContract.code.length > 0, InvalidImplementation());

    (bool success, bytes memory r) = implementationContract.call(
      abi.encodeWithSignature("supportsInterface(bytes4)", type(IInitializable).interfaceId)
    );

    require(success && abi.decode(r, (bool)), InvalidImplementation());

    (success,) = address(implementationContract).delegatecall(abi.encodeWithSignature("initialize(bytes)", data));
    emit ImplementationInitialized();

    require(success, InvalidImplementation());

    ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value = implementationContract;
    admin_ = msg.sender;
  }

  modifier onlyAdmin() {
    if (msg.sender == admin_) {
      _;
    } else {
      fallback_(ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value);
    }
  }

  function admin() external onlyAdmin returns (address) {
    return admin_;
  }

  function implementation() external onlyAdmin returns (address) {
    return ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value;
  }

  receive() external payable {
    revert ITransparentUpgradeableProxy.ReceiveUnsupported();
  }

  fallback() external payable {
    fallback_(ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value);
  }

  function fallback_(address implementationContract) private {
    require(msg.sender != admin_, InvalidAdminCall());

    assembly {
      calldatacopy(0x00, 0x00, calldatasize())

      let result := delegatecall(gas(), implementationContract, 0x00, calldatasize(), 0x00, 0x00)

      returndatacopy(0x00, 0x00, returndatasize())

      switch result
      case 0 { revert(0x00, returndatasize()) }
      default { return(0x00, returndatasize()) }
    }
  }
}
