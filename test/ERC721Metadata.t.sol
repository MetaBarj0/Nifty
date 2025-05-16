// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { IERC721Metadata } from "../src/interfaces/IERC721Metadata.sol";
import { Test } from "forge-std/Test.sol";

contract ERC721Tests is Test {
  Nifty private nifty;

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
