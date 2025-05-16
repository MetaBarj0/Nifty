// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { Nifty } from "../src/Nifty.sol";
import { IERC721 } from "../src/interfaces/IERC721.sol";
import { IERC721Enumerable } from "../src/interfaces/IERC721Enumerable.sol";
import { IERC721Mintable } from "../src/interfaces/IERC721Mintable.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";
import { Test } from "forge-std/Test.sol";

contract NiftyTests is Test, NiftyTestUtils {
  address private bob;
  address private alice;

  function setUp() public {
    nifty = new Nifty();
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function test_mint_throw_ifNotPaid() public {
    vm.expectRevert(IERC721Mintable.WrongPaymentValue.selector);
    nifty.mint(bob, 42);
  }

  function test_mint_throws_forZeroDestinationAddress() public {
    vm.expectRevert(IERC721Mintable.InvalidAddress.selector);

    paidMint(address(0), 0);
  }

  function test_mint_fails_forAlreadyMintedTokenId() public {
    paidMint(bob, 42);

    vm.expectRevert(IERC721Mintable.TokenAlreadyMinted.selector);

    paidMint(bob, 42);

    assertEq(nifty.balanceOf(bob), 1);
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

  function test_transferOwnership_throws_ifNotCurrentOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.transferOwnership(alice);

    vm.stopPrank();
  }

  function test_transferOwnership_succeeds_ifCurrentOwner() public {
    address oldPendingOwner = nifty.pendingOwner();

    nifty.transferOwnership(alice);

    assertEq(address(0), oldPendingOwner);
    assertEq(address(this), nifty.owner());
    assertEq(alice, nifty.pendingOwner());
  }

  function test_acceptOwnership_throws_ifPendingOwnerIsNotSender() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.acceptOwnership();

    vm.stopPrank();
  }

  function test_acceptOwnership_succeeds_ifPendingOwnerIsSender() public {
    address creatorBeforeOwnershipTransfer = nifty.creator();

    nifty.transferOwnership(alice);

    address ownerBeforeAccept = nifty.owner();
    address pendingOwnerBeforeAccept = nifty.pendingOwner();

    vm.startPrank(alice);
    nifty.acceptOwnership();
    vm.stopPrank();

    assertEq(creatorBeforeOwnershipTransfer, address(this));
    assertEq(nifty.creator(), address(this));

    assertEq(address(this), ownerBeforeAccept);
    assertEq(nifty.owner(), alice);

    assertEq(alice, pendingOwnerBeforeAccept);
    assertEq(nifty.pendingOwner(), address(0));
  }

  function test_renounceOwnership_throws_ifNotOwner() public {
    vm.expectRevert(INifty.Unauthorized.selector);

    vm.startPrank(alice);
    nifty.renounceOwnership();
    vm.stopPrank();
  }

  function test_renounceOwnership_throws_ifOwnerAndPendingOwnerSet() public {
    nifty.transferOwnership(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.renounceOwnership();
  }

  function test_renounceOwnership_succeeds_ifOwnerAndNoPendingOwner() public {
    address oldOwner = nifty.owner();

    nifty.renounceOwnership();

    assertEq(oldOwner, address(this));
    assertEq(nifty.owner(), address(0));
  }
}
