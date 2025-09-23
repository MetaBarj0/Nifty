// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "../src/interfaces/INifty.sol";

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { FailingReceiver, InvalidReceiver, NonCompliantReceiver, ValidReceiver } from "./Mocks.sol";
import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract ERC721TokenReceiverTests is Test, NiftyTestUtils {
  address private alice;
  InvalidReceiver private invalidReceiver;
  FailingReceiver private failingReceiver;
  NonCompliantReceiver private nonCompliantReceiver;
  ValidReceiver private validReceiver;

  function setUp() public {
    nifty = new Nifty();

    invalidReceiver = new InvalidReceiver();
    failingReceiver = new FailingReceiver();
    nonCompliantReceiver = new NonCompliantReceiver();
    validReceiver = new ValidReceiver();
    alice = makeAddr("Alice");
  }

  function test_mint_throws_withInvalidReceiverContract() public {
    vm.expectPartialRevert(INifty.InvalidReceiver.selector);
    paidMint(address(invalidReceiver), 0);
  }

  function test_mint_throws_withFailingReceiverContract() public {
    vm.expectRevert(FailingReceiver.OhShit.selector);
    paidMint(address(failingReceiver), 0);
  }

  function test_mint_throws_withNonCompliantReceiverContract() public {
    vm.expectPartialRevert(INifty.InvalidReceiver.selector);
    paidMint(address(nonCompliantReceiver), 0);
  }

  function test_safeTransferFrom_throws_withInvalidReceiverContract() public {
    paidMint(alice, 0);

    vm.startPrank(alice);
    vm.expectPartialRevert(INifty.InvalidReceiver.selector);
    nifty.safeTransferFrom(alice, address(invalidReceiver), 0);
    vm.stopPrank();
  }

  function test_safeTransferFrom_throws_withFailingReceiverContract() public {
    paidMint(alice, 0);

    vm.startPrank(alice);
    vm.expectRevert();
    nifty.safeTransferFrom(alice, address(invalidReceiver), 0);
    vm.stopPrank();
  }

  function test_safeTransferFrom_throws_withNonCompliantReceiverContract() public {
    paidMint(alice, 0);

    vm.startPrank(alice);
    vm.expectRevert();
    nifty.safeTransferFrom(alice, address(nonCompliantReceiver), 0);
    vm.stopPrank();
  }

  function test_mint_succeeds_WithValidReceiverContract() public {
    vm.expectEmit();
    emit ValidReceiver.Received(address(validReceiver), address(0), 0);
    paidMint(address(validReceiver), 0);

    assertEq(nifty.balanceOf(address(validReceiver)), 1);
  }

  function test_safeTransferFrom_succeeds_withValidReceiverContract() public {
    paidMint(alice, 0);

    vm.startPrank(alice);
    vm.expectEmit();
    emit ValidReceiver.Received(alice, alice, 0);
    nifty.safeTransferFrom(alice, address(validReceiver), 0, "validReceiver test");
    vm.stopPrank();

    assertEq(nifty.balanceOf(address(validReceiver)), 1);
  }
}
