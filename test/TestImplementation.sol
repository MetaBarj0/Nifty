// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC165 } from "../src/ERC165.sol";
import { IInitializable } from "../src/interfaces/IInitializable.sol";

contract TestImplementation is ERC165, IInitializable {
  uint256 public foo;

  function initialize(bytes calldata data) external override {
    (uint256 value) = abi.decode(data, (uint256));
    foo = value;
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == type(IInitializable).interfaceId || super.supportsInterface(interfaceId);
  }

  function admin() external pure returns (string memory) {
    return "admin from implementation";
  }

  function implementation() external pure returns (string memory) {
    return "implementation from implementation";
  }

  function inc() external {
    foo++;
  }
}
