// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IERC721 } from "../src/interfaces/IERC721.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract ERC721Ownable2StepsTests is Test, NiftyTestUtils {
  address private bob;
  address private alice;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
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

    nifty.transferOwnership(alice);
    nifty.transferOwnership(address(0));
    nifty.renounceOwnership();

    assertEq(oldOwner, address(this));
    assertEq(nifty.owner(), address(0));
  }
}
