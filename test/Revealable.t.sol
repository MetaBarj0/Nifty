// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Nifty } from "../src/Nifty.sol";
import { IMintable } from "../src/interfaces/IMintable.sol";

import { INifty } from "../src/interfaces/INifty.sol";
import { IRevealable } from "../src/interfaces/IRevealable.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";
import { Test } from "forge-std/Test.sol";

contract RevealableTests is Test, NiftyTestUtils {
  address private alice;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
  }

  function test_tokenURI_isEmpty_beforeCommitRevealPropertiesCall() public {
    paidMint(alice, 0);

    assertEq(nifty.tokenURI(0), "");
  }

  function test_commitRevealProperties_throws_ifNotCalledByOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.commitRevealProperties(0, "", 0, 0);

    vm.stopPrank();
  }

  function test_commitRevealProperties_throws_ifBaseURIHashIsZero() public {
    vm.expectRevert(IRevealable.InvalidRevealProperties.selector);
    nifty.commitRevealProperties(0, "", 0, 0);
  }

  function test_commitRevealProperties_throws_ifAllTokenURIBeforeRevealIsEmpty() public {
    vm.expectRevert(IRevealable.InvalidRevealProperties.selector);
    nifty.commitRevealProperties(uint256(keccak256("an/address")), "", 0, 0);
  }

  function test_commitRevealProperties_throws_ifRevealTimeLockIsIncorrect() public {
    vm.expectRevert(IRevealable.InvalidRevealProperties.selector);
    nifty.commitRevealProperties(uint256(keccak256("revealed/address")), "before/reveal/address", 0, 1 days);
  }

  function test_commitRevealProperties_throws_ifWithdrawTimeLockIsIncorrect() public {
    vm.expectRevert(IRevealable.InvalidRevealProperties.selector);
    nifty.commitRevealProperties(uint256(keccak256("revealed/address")), "before/reveal/address", 1 days, 0);
  }

  function test_commitRevealProperties_succeeds_ifCalledWithCorrectParameterSet() public {
    paidMint(alice, 0);

    assertEq(nifty.tokenURI(0), "");

    nifty.commitRevealProperties(uint256(keccak256("revealed/address")), "before/reveal/address", 1 days, 2 days);

    assertEq(nifty.tokenURI(0), "before/reveal/address");
  }

  function test_reveal_throws_ifNotOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.reveal("");

    vm.stopPrank();
  }

  function test_reveal_throws_withIncorrectBaseURI() public {
    nifty.commitRevealProperties(uint256(keccak256("correct/base/address")), "before/reveal/address", 1 weeks, 2 days);

    vm.expectRevert(IRevealable.WrongPreimage.selector, 2);
    nifty.reveal("");
    nifty.reveal("incorrect/base/address");
  }

  function test_tokenURI_succeedsAndReturnFinalURI_whenRevealIsDone() public {
    paidMint(alice, 0);

    nifty.commitRevealProperties(uint256(keccak256("correct/base/address")), "before/reveal/address", 1 days, 3 days);

    assertEq(nifty.tokenURI(0), "before/reveal/address");

    nifty.reveal("correct/base/address");

    assertEq(nifty.tokenURI(0), "correct/base/address/0.json");
  }

  function test_allTimeLocks_return0_whenCommitRevealPropertiesHasNotBeenCalled() public view {
    assertEq(0, nifty.revealTimeLockEnd());
    assertEq(0, nifty.withdrawTimeLockEnd());
  }

  function test_allTimeLockEndFunctions_returnsTimeRelativeToBlockTimestamp_whenCommitRevealPropertiesHasBeenCalled()
    public
  {
    nifty.commitRevealProperties(uint256(keccak256("correct/base/address")), "before/reveal/address", 123 hours, 1 days);

    assertEq(block.timestamp + 123 hours, nifty.revealTimeLockEnd());
    assertEq(block.timestamp + 123 hours + 1 days, nifty.withdrawTimeLockEnd());
  }
}
