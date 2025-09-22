// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProxyStorage } from "./ProxyStorage.sol";

import { ProxyStorage } from "./ProxyStorage.sol";
import { ITransparentUpgradeableProxy } from "./interfaces/ITransparentUpgradeableProxy.sol";

contract Proxy is ITransparentUpgradeableProxy {
  bytes32 public constant IMPLEMENTATION_SLOT = bytes32(keccak256("ITransparentUpgradeableProxy.implementation"));

  address private immutable admin_;

  constructor(address implementationContract) {
    require(implementationContract.code.length > 0, InvalidImplementation());

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
