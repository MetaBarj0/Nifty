// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IMintable } from "../../src/interfaces/token/IMintable.sol";

import { Nifty } from "../../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract MintableTests is Test, NiftyTestUtils {
  address private bob;

  function setUp() public {
    bob = makeAddr("Bob");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_mint_throw_ifNotPaid(SUTDatum memory sutDatum) public {
    vm.expectRevert(IMintable.WrongPaymentValue.selector);
    callForVoid(sutDatum.sut, sutDatum.user, abi.encodeWithSignature("mint(address,uint256)", bob, 42));
  }

  function table_mint_throws_forZeroDestinationAddress(SUTDatum memory sutDatum) public {
    vm.expectRevert(IMintable.InvalidAddress.selector);
    paidMintNew(sutDatum.sut, address(0), 0);
  }

  function table_mint_fails_forAlreadyMintedTokenId(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, bob, 42);

    vm.expectRevert(IMintable.TokenAlreadyMinted.selector);
    paidMintNew(sut, bob, 42);

    assertEq(1, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", bob)));
  }
}
