// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IPausable } from "../src/interfaces/IPausable.sol";
import { INifty } from "../src/interfaces/token/INifty.sol";

import { Nifty } from "../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract PausableTests is Test, NiftyTestUtils {
  address private alice;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
  }

  function test_pause_throws_ifNotCalledByOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.pause();

    vm.stopPrank();
  }

  function test_resume_throws_ifNotCalledByOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.resume();

    vm.stopPrank();
  }

  function test_paused_returnsFalse_IfNiftyIsNotPaused() public view {
    assertEq(false, nifty.paused());
  }

  function test_paused_returnsTrue_IfNiftyIsPaused() public {
    nifty.pause();

    assertEq(true, nifty.paused());
  }

  function test_pause_locksMintAndBurn() public {
    nifty.pause();

    vm.expectRevert(IPausable.MintAndBurnPaused.selector);
    paidMint(alice, 123);

    vm.startPrank(alice);

    vm.expectRevert(IPausable.MintAndBurnPaused.selector);
    nifty.burn(0);

    vm.stopPrank();
  }

  function test_resume_unlocksMintAndBurn() public {
    nifty.pause();
    nifty.resume();

    paidMint(alice, 123);
    assertEq(alice, nifty.ownerOf(123));

    vm.startPrank(alice);
    nifty.burn(123);
    vm.stopPrank();

    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.ownerOf(123);
  }
}
