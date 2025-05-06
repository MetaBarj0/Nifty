// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { IERC721 } from "../src/interfaces/IERC721.sol";
import { INifty } from "../src/interfaces/INifty.sol";
import { Test } from "forge-std/Test.sol";

contract NiftyTests is Test {
  INifty private nifty;
  address private bob;

  function setUp() public {
    nifty = new Nifty();
    bob = makeAddr("Bob");
  }

  function test_mint_succeeds_forFreeAndForAnyoneWhoWantsWithValidTokenId() public {
    vm.expectEmit();
    emit IERC721.Transfer(address(0), bob, 42);

    nifty.mint(bob, 42);

    assertEq(nifty.balanceOf(bob), 1);
  }

  function test_mint_fails_forAlreadyMintedTokenId() public {
    nifty.mint(bob, 42);

    vm.expectRevert(INifty.TokenAlreadyMinted.selector);

    nifty.mint(bob, 42);

    assertEq(nifty.balanceOf(bob), 1);
  }
}
