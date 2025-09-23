// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721Metadata } from "../src/interfaces/token/IERC721Metadata.sol";
import { INifty } from "../src/interfaces/token/INifty.sol";

import { Nifty } from "../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract ERC721MetadataTests is Test, NiftyTestUtils {
  address private alice;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
  }

  function test_name_succeeds_afterDeploy() public view {
    assertEq(nifty.name(), "Nifty");
  }

  function test_symbol_succeeds_afterDeploy() public view {
    assertEq(nifty.symbol(), "NFT xD");
  }

  function test_tokenURI_throws_forInvalidTokenId() public {
    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.tokenURI(0);
  }

  function test_tokenURI_throws_forBurntToken() public {
    paidMint(alice, 0);

    vm.startPrank(alice);
    nifty.burn(0);
    vm.stopPrank();

    vm.expectRevert(INifty.InvalidTokenId.selector);
    assertEq(nifty.tokenURI(0), "");
  }
}
