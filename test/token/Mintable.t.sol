// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "../../src/interfaces/INifty.sol";
import { IMintable } from "../../src/interfaces/token/IMintable.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract MintableTests is Test, NiftyTestUtils {
  address private bob;

  function setUp() public {
    bob = makeAddr("Bob");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutDataForNifty();
  }

  function table_mint_throws_forZeroDestinationAddress(SUTDatum memory sutDatum) public {
    vm.expectRevert(IMintable.InvalidAddress.selector);
    paidMint(sutDatum.sut, address(0), 0);
  }

  function table_mint_throws_forAlreadyMintedTokenId(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, bob, true);

    paidMint(sut, bob, 42);

    vm.expectRevert(IMintable.TokenAlreadyMinted.selector);
    paidMint(sut, bob, 42);

    assertEq(1, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", bob)));
  }

  function table_mint_throw_forUnauthorizedMinter(SUTDatum memory sutDatum) public {
    vm.expectRevert(INifty.Unauthorized.selector);
    paidMint(sutDatum.sut, bob, 0);
  }

  function table_authorizeMinter_throwsWhenNotCalledByOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    expectCallRevert(
      INifty.Unauthorized.selector, sut, bob, abi.encodeWithSignature("authorizeMinter(address,bool)", bob, true)
    );
  }

  function table_authorizeMinter_throwsWhenAuthorizingOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    expectCallRevert(
      INifty.Unauthorized.selector,
      sut,
      niftyOwner,
      abi.encodeWithSignature("authorizeMinter(address,bool)", niftyOwner, true)
    );
  }

  function table_authorizeMinter_emit_forValidNewMinter(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    vm.expectEmit();
    emit IMintable.MinterAuthorized(bob, true);

    callForVoid(sut, niftyOwner, abi.encodeWithSignature("authorizeMinter(address,bool)", bob, true));
  }
}
