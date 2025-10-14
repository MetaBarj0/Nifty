// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "../interfaces/INifty.sol";
import { ITransparentUpgradeableProxy } from "../interfaces/proxy/ITransparentUpgradeableProxy.sol";

import { ProxyStorage } from "./ProxyStorage.sol";

contract TransparentUpgradeableProxy is ITransparentUpgradeableProxy {
  // NOTE: bytes32(keccak256("ITransparentUpgradeableProxy.implementation"));
  bytes32 public constant IMPLEMENTATION_SLOT = 0x89cc2b981328df209fd92734b973154b4a0db2c602160538b307a6538510f52c;

  // NOTE: bytes32(keccak256("ITransparentUpgradeableProxy.admin"));
  bytes32 public constant ADMIN_SLOT = 0x17da58f47bb1f038be851443e55e9d9763e9c1c06cc9b1f1bfac7eebac2b38b7;

  constructor(address implementationContract, bytes memory encodedCall) {
    require(implementationContract.code.length > 0, InvalidImplementation());

    if (encodedCall.length > 0) {
      (bool success,) = address(implementationContract).delegatecall(encodedCall);
      require(success, InvalidImplementation());
    }

    emit ImplementationInitialized();

    ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value = implementationContract;
    ProxyStorage.getAddressSlot(ADMIN_SLOT).value = msg.sender;
  }

  modifier onlyAdmin() {
    if (getAdmin_() == msg.sender) {
      // NOTE: coverage reports this line is not covered but it's not
      // true. If you add a console.log() for isntance instruction
      // before _; it reports this line covered
      _;
    } else {
      fallback_(ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value);
    }
  }

  function admin() external onlyAdmin returns (address) {
    return getAdmin_();
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

  function upgradeToAndCall(address newImplementation, bytes calldata encodedCall) external {
    require(getAdmin_() == msg.sender, INifty.Unauthorized());
    require(newImplementation.code.length > 0, InvalidImplementation());

    if (encodedCall.length > 0) {
      (bool success,) = address(newImplementation).delegatecall(encodedCall);
      require(success, InvalidImplementation());
    }

    emit ImplementationChanged(ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value);

    ProxyStorage.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
  }

  function changeAdmin(address newAdmin) external {
    require(getAdmin_() == msg.sender, INifty.Unauthorized());

    emit AdminChanged(getAdmin_(), newAdmin);

    ProxyStorage.getAddressSlot(ADMIN_SLOT).value = newAdmin;
  }

  function fallback_(address implementationContract) private {
    require(msg.sender != getAdmin_(), InvalidAdminCall());

    assembly {
      calldatacopy(0x00, 0x00, calldatasize())

      let result := delegatecall(gas(), implementationContract, 0x00, calldatasize(), 0x00, 0x00)

      returndatacopy(0x00, 0x00, returndatasize())

      switch result
      case 0 { revert(0x00, returndatasize()) }
      default { return(0x00, returndatasize()) }
    }
  }

  function getAdmin_() private view returns (address) {
    return ProxyStorage.getAddressSlot(ADMIN_SLOT).value;
  }
}
