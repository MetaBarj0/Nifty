// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { INifty } from "../src/interfaces/INifty.sol";
import { IOwnable2Steps } from "../src/interfaces/IOwnable2Steps.sol";

import { Ownable2Steps } from "../src/Ownable2Steps.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

contract Ownable2StepsTests is Test, NiftyTestUtils {
  address private bob;
  address private alice;
  IOwnable2Steps ownable2Steps;

  function setUp() public {
    ownable2Steps = new Ownable2Steps(address(this));
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function test_transferOwnership_throws_ifNotCurrentOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    ownable2Steps.transferOwnership(alice);

    vm.stopPrank();
  }

  function test_transferOwnership_succeeds_ifCurrentOwner() public {
    address oldPendingOwner = ownable2Steps.pendingOwner();

    vm.expectEmit();
    emit IOwnable2Steps.OwnerChanging(alice);
    ownable2Steps.transferOwnership(alice);

    assertEq(address(0), oldPendingOwner);
    assertEq(address(this), ownable2Steps.owner());
    assertEq(alice, ownable2Steps.pendingOwner());
  }

  function test_acceptOwnership_throws_ifPendingOwnerIsNotSender() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    ownable2Steps.acceptOwnership();

    vm.stopPrank();
  }

  function test_acceptOwnership_succeeds_ifPendingOwnerIsSender() public {
    address ownerBeforeOwnershipTransfer = ownable2Steps.owner();

    ownable2Steps.transferOwnership(alice);

    address ownerBeforeAccept = ownable2Steps.owner();
    address pendingOwnerBeforeAccept = ownable2Steps.pendingOwner();

    vm.startPrank(alice);

    vm.expectEmit();
    emit IOwnable2Steps.OwnerChanged(ownerBeforeOwnershipTransfer, alice);
    ownable2Steps.acceptOwnership();

    vm.stopPrank();

    assertEq(ownerBeforeOwnershipTransfer, address(this));
    assertEq(address(this), ownerBeforeAccept);
    assertEq(alice, ownable2Steps.owner());
    assertEq(alice, pendingOwnerBeforeAccept);
    assertEq(address(0), ownable2Steps.pendingOwner());
  }

  function test_renounceOwnership_throws_ifNotOwner() public {
    vm.expectRevert(INifty.Unauthorized.selector);

    vm.startPrank(alice);
    ownable2Steps.renounceOwnership();
    vm.stopPrank();
  }

  function test_renounceOwnership_throws_ifOwnerAndPendingOwnerSet() public {
    ownable2Steps.transferOwnership(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    ownable2Steps.renounceOwnership();
  }

  function test_renounceOwnership_succeeds_ifOwnerAndNoPendingOwner() public {
    address oldOwner = ownable2Steps.owner();

    ownable2Steps.transferOwnership(alice);
    ownable2Steps.transferOwnership(address(0));

    vm.expectEmit();
    emit IOwnable2Steps.OwnerChanged(oldOwner, address(0));
    ownable2Steps.renounceOwnership();

    assertEq(address(this), oldOwner);
    assertEq(address(0), ownable2Steps.owner());
  }
}
