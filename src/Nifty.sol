// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract Nifty {
  address public immutable creator;

  constructor() {
    creator = msg.sender;
  }
}
