// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { IERC721Mintable } from "../src/interfaces/IERC721Mintable.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract ERC721RevealableTests is Test, NiftyTestUtils {
  address private alice;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
  }
}
