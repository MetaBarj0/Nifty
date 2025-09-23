// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IMintable } from "../src/interfaces/IMintable.sol";

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract MintableTests is Test, NiftyTestUtils {
  address private bob;

  function setUp() public {
    nifty = new Nifty();

    bob = makeAddr("Bob");
  }

  function test_mint_throw_ifNotPaid() public {
    vm.expectRevert(IMintable.WrongPaymentValue.selector);
    nifty.mint(bob, 42);
  }

  function test_mint_throws_forZeroDestinationAddress() public {
    vm.expectRevert(IMintable.InvalidAddress.selector);

    paidMint(address(0), 0);
  }

  function test_mint_fails_forAlreadyMintedTokenId() public {
    paidMint(bob, 42);

    vm.expectRevert(IMintable.TokenAlreadyMinted.selector);

    paidMint(bob, 42);

    assertEq(nifty.balanceOf(bob), 1);
  }
}
