// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { Nifty } from "../src/Nifty.sol";
import { IERC721 } from "../src/interfaces/IERC721.sol";
import { IERC721Enumerable } from "../src/interfaces/IERC721Enumerable.sol";
import { INifty } from "../src/interfaces/INifty.sol";
import { Test } from "forge-std/Test.sol";

contract NiftyTests is Test {
  Nifty private nifty;
  address private bob;
  address private alice;

  function setUp() public {
    nifty = new Nifty();
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function test_mint_succeeds_forFreeAndForAnyoneWhoWantsWithValidTokenId() public {
    vm.expectEmit();
    emit IERC721.Transfer(address(0), bob, 42);

    nifty.mint(bob, 42);

    assertEq(nifty.balanceOf(bob), 1);
  }

  function test_mint_throws_forZeroDestinationAddress() public {
    vm.expectRevert(INifty.InvalidAddress.selector);

    nifty.mint(address(0), 0);
  }

  function test_mint_fails_forAlreadyMintedTokenId() public {
    nifty.mint(bob, 42);

    vm.expectRevert(INifty.TokenAlreadyMinted.selector);

    nifty.mint(bob, 42);

    assertEq(nifty.balanceOf(bob), 1);
  }

  function test_burn_throw_forNotMintedToken() public {
    vm.expectRevert(INifty.InvalidTokenId.selector);

    nifty.burn(0);
  }

  function test_burn_throws_forExistingTokenNotOwnedBySender() public {
    nifty.mint(alice, 0);

    vm.startPrank(bob);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.burn(0);

    vm.stopPrank();
  }

  function test_burn_succeeds_decreasingTotalSupply() public {
    nifty.mint(alice, 0);
    nifty.mint(alice, 1);
    uint256 supplyBeforeBurn = nifty.totalSupply();

    vm.startPrank(alice);
    nifty.burn(1);
    vm.stopPrank();

    assertEq(2, supplyBeforeBurn);
    assertEq(1, nifty.totalSupply());
  }

  function test_burn_succeeds_atRemovingTokenOwnership() public {
    nifty.mint(alice, 0);
    address token0OwnerBeforeBurn = nifty.ownerOf(0);

    vm.startPrank(alice);
    nifty.burn(0);
    vm.stopPrank();

    assertEq(token0OwnerBeforeBurn, alice);
    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.ownerOf(0);
  }

  function test_burn_succeeds_atDecreasingOwnerBalance() public {
    nifty.mint(alice, 0);
    uint256 balanceBeforeBurn = nifty.balanceOf(alice);

    vm.startPrank(alice);
    nifty.burn(0);
    vm.stopPrank();

    assertEq(1, balanceBeforeBurn);
    assertEq(0, nifty.balanceOf(alice));
  }

  function test_burn_succeeds_atRemovingBurntTokenApproval() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);
    nifty.approve(bob, 0);
    vm.stopPrank();

    address approvedBeforeBurn = nifty.getApproved(0);

    vm.startPrank(alice);
    nifty.burn(0);
    vm.stopPrank();

    assertEq(bob, approvedBeforeBurn);
    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.getApproved(0);
  }

  function test_burn_succeeds_ifQueriedByApprovedAddress() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);
    nifty.approve(bob, 0);
    vm.stopPrank();

    vm.startPrank(bob);
    nifty.burn(0);
    vm.stopPrank();
  }

  function test_burn_succeeds_ifQueriedByOperator() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);
    nifty.setApprovalForAll(bob, true);
    vm.stopPrank();

    vm.startPrank(bob);
    nifty.burn(0);
    vm.stopPrank();
  }
}
