// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { IERC721 } from "../src/interfaces/IERC721.sol";
import { INifty } from "../src/interfaces/INifty.sol";
import { Test } from "forge-std/Test.sol";

contract ERC721Tests is Test {
  Nifty private nifty;
  address private alice;
  address private bob;
  address private chuck;
  address private david;

  function setUp() public {
    nifty = new Nifty();
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
    chuck = makeAddr("Chuck");
    david = makeAddr("David");
  }

  function test_balanceOf_returns0_forUserHavingNoToken() public view {
    assertEq(0, nifty.balanceOf(bob));
  }

  function test_balanceOf_succeeds_returnsUserBalance() public {
    for (uint256 index = 0; index < 42; index++) {
      nifty.mint(alice, index);
    }

    assertEq(42, nifty.balanceOf(alice));
  }

  function test_ownerOf_throws_forUnmintedTokens() public {
    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.ownerOf(42);
  }

  function test_getApprove_throws_forInvalidToken() public {
    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.getApproved(0);
  }

  function test_approve_throws_ifSenderIsNotOwner() public {
    nifty.mint(alice, 0);

    vm.startPrank(bob);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.approve(chuck, 0);

    vm.stopPrank();
  }

  function test_approve_succeeds_ifSenderIsOwner() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);

    vm.expectEmit();
    emit IERC721.Approval(alice, bob, 0);

    nifty.approve(bob, 0);

    vm.stopPrank();

    assertEq(nifty.getApproved(0), bob);
  }

  function test_setApprovalForAll_succeeds_andEmitApprovalForAll() public {
    nifty.mint(alice, 0);
    nifty.mint(alice, 1);

    vm.startPrank(alice);

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, bob, true);
    nifty.setApprovalForAll(bob, true);

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, chuck, true);
    nifty.setApprovalForAll(chuck, true);

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, bob, false);
    nifty.setApprovalForAll(bob, false);

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, chuck, false);
    nifty.setApprovalForAll(chuck, false);

    vm.stopPrank();
  }

  function test_isApprovedForAll_succeeds_andProvesSeveralOperatorsSupportForOwner() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);

    nifty.setApprovalForAll(bob, true);
    nifty.setApprovalForAll(chuck, true);

    assertEq(true, nifty.isApprovedForAll(alice, bob));
    assertEq(true, nifty.isApprovedForAll(alice, chuck));

    nifty.setApprovalForAll(bob, false);
    nifty.setApprovalForAll(chuck, false);

    assertEq(false, nifty.isApprovedForAll(alice, bob));
    assertEq(false, nifty.isApprovedForAll(alice, chuck));

    vm.stopPrank();

    assertEq(false, nifty.isApprovedForAll(alice, david));
  }

  function test_approve_throws_ifSenderIsNotOperator() public {
    nifty.mint(alice, 0);

    vm.startPrank(bob);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.approve(chuck, 0);

    vm.stopPrank();
  }

  function test_approve_succeeds_ifSenderisOperator() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);
    nifty.setApprovalForAll(chuck, true);
    vm.stopPrank();

    vm.startPrank(chuck);

    vm.expectEmit();
    emit IERC721.Approval(alice, bob, 0);

    nifty.approve(bob, 0);

    vm.stopPrank();
  }

  function test_transferFrom_throws_unsafeTransferFromIsUnsupported() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);

    vm.expectRevert(INifty.Unsupported.selector);
    nifty.transferFrom(alice, bob, 0);

    vm.stopPrank();
  }

  function test_safeTransferFrom_throws_ifNotOwnerNorApprovedNorOperator() public {
    nifty.mint(alice, 0);

    vm.startPrank(bob);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.safeTransferFrom(bob, chuck, 0);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.safeTransferFrom(alice, chuck, 0);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.safeTransferFrom(bob, chuck, 1);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.safeTransferFrom(alice, chuck, 1);

    vm.stopPrank();
  }

  function test_safeTransferFrom_succeeds_ifOwner() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);

    vm.expectEmit();
    emit IERC721.Transfer(alice, bob, 0);
    nifty.safeTransferFrom(alice, bob, 0);

    vm.stopPrank();

    assertEq(0, nifty.balanceOf(alice));
    assertEq(1, nifty.balanceOf(bob));
    assertEq(bob, nifty.ownerOf(0));
  }

  function test_safeTransferFrom_succeeds_ifApproved() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);
    nifty.approve(bob, 0);
    vm.stopPrank();

    vm.startPrank(bob);
    vm.expectEmit();
    emit IERC721.Transfer(alice, chuck, 0);
    nifty.safeTransferFrom(alice, chuck, 0);

    vm.stopPrank();

    assertEq(0, nifty.balanceOf(alice));
    assertEq(0, nifty.balanceOf(bob));
    assertEq(1, nifty.balanceOf(chuck));
    assertEq(chuck, nifty.ownerOf(0));
  }

  function test_safeTransferFrom_succeeds_ifOperator() public {
    nifty.mint(alice, 0);
    nifty.mint(alice, 1);

    vm.startPrank(alice);
    nifty.setApprovalForAll(bob, true);
    vm.stopPrank();

    vm.startPrank(bob);

    vm.expectEmit();
    emit IERC721.Transfer(alice, chuck, 0);
    nifty.safeTransferFrom(alice, chuck, 0);

    vm.expectEmit();
    emit IERC721.Transfer(alice, chuck, 1);
    nifty.safeTransferFrom(alice, chuck, 1);

    vm.stopPrank();

    assertEq(0, nifty.balanceOf(alice));
    assertEq(0, nifty.balanceOf(bob));
    assertEq(2, nifty.balanceOf(chuck));
    assertEq(chuck, nifty.ownerOf(0));
    assertEq(chuck, nifty.ownerOf(1));
  }

  function test_safeTransferFrom_succeeds_andResetApproval() public {
    nifty.mint(alice, 0);

    vm.startPrank(alice);
    nifty.approve(bob, 0);
    vm.stopPrank();

    assertEq(bob, nifty.getApproved(0));

    vm.startPrank(alice);
    nifty.safeTransferFrom(alice, chuck, 0);
    vm.stopPrank();

    assertEq(address(0), nifty.getApproved(0));
  }
}
