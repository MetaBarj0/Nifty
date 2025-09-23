// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IERC721 } from "../src/interfaces/token/IERC721.sol";
import { INifty } from "../src/interfaces/token/INifty.sol";

import { Nifty } from "../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract BurnableTests is Test, NiftyTestUtils {
  address private bob;
  address private alice;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function test_burn_throw_forNotMintedToken() public {
    vm.expectRevert(INifty.InvalidTokenId.selector);

    nifty.burn(0);
  }

  function test_burn_throws_forExistingTokenNotOwnedBySender() public {
    paidMint(alice, 0);

    vm.startPrank(bob);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.burn(0);

    vm.stopPrank();
  }

  function test_burn_succeeds_decreasingTotalSupply() public {
    paidMint(alice, 0);
    paidMint(alice, 1);
    uint256 supplyBeforeBurn = nifty.totalSupply();

    vm.startPrank(alice);
    nifty.burn(1);
    vm.stopPrank();

    assertEq(2, supplyBeforeBurn);
    assertEq(1, nifty.totalSupply());
  }

  function test_burn_succeeds_atRemovingTokenOwnership() public {
    paidMint(alice, 0);
    address token0OwnerBeforeBurn = nifty.ownerOf(0);

    vm.startPrank(alice);
    nifty.burn(0);
    vm.stopPrank();

    assertEq(token0OwnerBeforeBurn, alice);
    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.ownerOf(0);
  }

  function test_burn_succeeds_atDecreasingOwnerBalance() public {
    paidMint(alice, 0);
    uint256 balanceBeforeBurn = nifty.balanceOf(alice);

    vm.startPrank(alice);
    nifty.burn(0);
    vm.stopPrank();

    assertEq(1, balanceBeforeBurn);
    assertEq(0, nifty.balanceOf(alice));
  }

  function test_burn_succeeds_atRemovingBurntTokenApproval() public {
    paidMint(alice, 0);

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
    paidMint(alice, 0);

    vm.startPrank(alice);
    nifty.approve(bob, 0);
    vm.stopPrank();

    vm.startPrank(bob);
    nifty.burn(0);
    vm.stopPrank();
  }

  function test_burn_succeeds_ifQueriedByOperator() public {
    paidMint(alice, 0);

    vm.startPrank(alice);
    nifty.setApprovalForAll(bob, true);
    vm.stopPrank();

    vm.startPrank(bob);
    nifty.burn(0);
    vm.stopPrank();
  }

  function test_burn_emitsTransferEvent_ifItSucceeds() public {
    paidMint(alice, 3);

    vm.startPrank(alice);

    vm.expectEmit();
    emit IERC721.Transfer(alice, address(0), 3);
    nifty.burn(3);

    vm.stopPrank();
  }
}
