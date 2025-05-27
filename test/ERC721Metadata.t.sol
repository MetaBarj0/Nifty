// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { IERC721Metadata } from "../src/interfaces/IERC721Metadata.sol";

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract ERC721Tests is Test, NiftyTestUtils {
  function setUp() public {
    nifty = new Nifty();
  }

  function test_name_succeeds_afterDeploy() public view {
    assertEq(nifty.name(), "Nifty");
  }

  function test_symbol_succeeds_afterDeploy() public view {
    assertEq(nifty.symbol(), "NFT xD");
  }
}
