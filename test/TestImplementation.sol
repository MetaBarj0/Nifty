// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract TestImplementation {
  uint256 public foo;

  constructor(uint256 value) {
    foo = value;
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
