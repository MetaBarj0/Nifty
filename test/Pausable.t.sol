// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IPausable } from "../src/interfaces/IPausable.sol";
import { INifty } from "../src/interfaces/token/INifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

contract PausableTests is Test, NiftyTestUtils {
  address private alice;

  function setUp() public {
    alice = makeAddr("Alice");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_pause_throws_ifNotCalledByOwner(SUTDatum memory sutDatum) public {
    expectCallRevert(INifty.Unauthorized.selector, sutDatum.sut, alice, abi.encodeWithSignature("pause()"));
  }

  function table_resume_throws_ifNotCalledByOwner(SUTDatum memory sutDatum) public {
    expectCallRevert(INifty.Unauthorized.selector, sutDatum.sut, alice, abi.encodeWithSignature("resume()"));
  }

  function table_paused_returnsFalse_IfNiftyIsNotPaused(SUTDatum memory sutDatum) public {
    assertFalse(callForBool(sutDatum.sut, sutDatum.user, abi.encodeWithSignature("paused()")));
  }

  function table_paused_returnsTrue_IfNiftyIsPaused(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("pause()"));

    assertTrue(callForBool(sut, user, abi.encodeWithSignature("paused()")));
  }

  function table_pause_locksMintAndBurn(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("pause()"));

    vm.expectRevert(IPausable.MintAndBurnPaused.selector);
    paidMintNew(sut, alice, 123);

    expectCallRevert(IPausable.MintAndBurnPaused.selector, sut, alice, abi.encodeWithSignature("burn(uint256)", 0));
  }

  function table_resume_unlocksMintAndBurn(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("pause()"));
    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("resume()"));

    paidMintNew(sut, alice, 123);

    assertEq(alice, callForAddress(sut, user, abi.encodeWithSignature("ownerOf(uint256)", 123)));

    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 123));

    expectCallRevert(INifty.InvalidTokenId.selector, sut, user, abi.encodeWithSignature("ownerOf(uint256)", 123));
  }
}
