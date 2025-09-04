// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";
import { IERC721Mintable } from "../src/interfaces/IERC721Mintable.sol";
import { IERC721Revealable } from "../src/interfaces/IERC721Revealable.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";
import { Test } from "forge-std/Test.sol";

contract ERC721RevealableTests is Test, NiftyTestUtils {
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
    nifty.commitRevealProperties(0, "", 0);

    vm.stopPrank();
  }

  function test_commitRevealProperties_throws_ifBaseURIHashIsZero() public {
    vm.expectRevert(IERC721Revealable.InvalidRevealProperties.selector);
    nifty.commitRevealProperties(0, "", 0);
  }

  function test_commitRevealProperties_throws_ifAllTokenURIBeforeRevealIsEmpty() public {
    vm.expectRevert(IERC721Revealable.InvalidRevealProperties.selector);
    nifty.commitRevealProperties(uint256(keccak256("an/address")), "", 0);
  }

  function test_commitRevealProperties_throws_ifRevealTimeLockIsIncorrect() public {
    vm.expectRevert(IERC721Revealable.InvalidRevealProperties.selector);
    nifty.commitRevealProperties(uint256(keccak256("revealed/address")), "before/reveal/address", 0);
  }

  function test_commitRevealProperties_succeeds_ifCalledWithCorrectParameterSet() public {
    paidMint(alice, 0);

    assertEq(nifty.tokenURI(0), "");

    nifty.commitRevealProperties(uint256(keccak256("revealed/address")), "before/reveal/address", 1000);

    assertEq(nifty.tokenURI(0), "before/reveal/address");
  }

  function test_reveal_throws_ifNotOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.reveal("");

    vm.stopPrank();
  }

  function test_reveal_throws_withIncorrectBaseURI() public {
    nifty.commitRevealProperties(uint256(keccak256("correct/base/address")), "before/reveal/address", 1);

    vm.expectRevert(IERC721Revealable.WrongPreimage.selector, 2);
    nifty.reveal("");
    nifty.reveal("incorrect/base/address");
  }

  function test_tokenURI_succeedsAndReturnFinalURI_whenRevealIsDone() public {
    paidMint(alice, 0);

    nifty.commitRevealProperties(uint256(keccak256("correct/base/address")), "before/reveal/address", 1);

    assertEq(nifty.tokenURI(0), "before/reveal/address");

    nifty.reveal("correct/base/address");

    assertEq(nifty.tokenURI(0), "correct/base/address/0.svg");
  }

  function test_revealTimeLockEnd_returns0_whenCommitRevealPropertiesHasNotBeenCalled() public view {
    assertEq(0, nifty.revealTimeLockEnd());
  }

  function test_revealTimeLockEnd_returnsTimeRelativeToBlockTimestamp_whenCommitRevealPropertiesHasBeenCalled() public {
    vm.warp(1000);

    nifty.commitRevealProperties(uint256(keccak256("correct/base/address")), "before/reveal/address", 123);

    assertEq(block.timestamp + 123, nifty.revealTimeLockEnd());
  }
}
