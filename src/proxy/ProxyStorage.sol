// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library ProxyStorage {
  struct AddressSlot {
    address value;
  }

  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
    assembly ("memory-safe") {
      r.slot := slot
    }
  }
}
