// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

contract ERC721EnumerableTests is Test {
  Nifty private nifty;
  address private alice;

  function setUp() public {
    nifty = new Nifty();
    alice = makeAddr("Alice");
  }
}
