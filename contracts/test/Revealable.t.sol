// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "../src/interfaces/INifty.sol";
import { IRevealable } from "../src/interfaces/IRevealable.sol";
import { IMintable } from "../src/interfaces/token/IMintable.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

contract RevealableTests is NiftyTestUtils {
  address private alice;

  function setUp() public {
    alice = makeAddr("Alice");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return testGetSutDataForNifty();
  }

  function table_tokenURI_isEmpty_beforeCommitRevealPropertiesCall(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    assertEq("", callForString(sut, user, abi.encodeWithSignature("tokenURI(uint256)", 0)));
  }

  function table_commitRevealProperties_throws_ifNotCalledByOwner(SUTDatum memory sutDatum) public {
    vm.expectRevert(INifty.Unauthorized.selector);
    callForVoid(
      sutDatum.sut, alice, abi.encodeWithSignature("commitRevealProperties(uint256,string,uint256)", 0, "", 0)
    );
  }

  function table_commitRevealProperties_throws_ifBaseURIHashIsZero(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    vm.expectRevert(IRevealable.InvalidRevealProperties.selector);
    callForVoid(sut, niftyOwner, abi.encodeWithSignature("commitRevealProperties(uint256,string,uint256)", 0, "", 0));
  }

  function table_commitRevealProperties_throws_ifAllTokenURIBeforeRevealIsEmpty(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    vm.expectRevert(IRevealable.InvalidRevealProperties.selector);
    callForVoid(
      sut,
      niftyOwner,
      abi.encodeWithSignature("commitRevealProperties(uint256,string,uint256)", uint256(keccak256("an/address")), "", 0)
    );
  }

  function table_commitRevealProperties_throws_ifRevealTimeLockIsIncorrect(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    vm.expectRevert(IRevealable.InvalidRevealProperties.selector);
    callForVoid(
      sut,
      niftyOwner,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256)",
        uint256(keccak256("revealed/address")),
        "before/reveal/address",
        0
      )
    );
  }

  function table_commitRevealProperties_succeeds_ifCalledWithCorrectParameterSet(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    assertEq("", callForString(sut, user, abi.encodeWithSignature("tokenURI(uint256)", 0)));

    uint256 commitment = uint256(keccak256("revealed/address"));

    vm.expectEmit();
    emit IRevealable.RevealPropertiesCommitted(commitment, "before/reveal/address", 1 days);
    callForVoid(
      sut,
      niftyOwner,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256)", commitment, "before/reveal/address", 1 days
      )
    );

    assertEq("before/reveal/address", callForString(sut, user, abi.encodeWithSignature("tokenURI(uint256)", 0)));
  }

  function table_reveal_throws_ifNotOwner(SUTDatum memory sutDatum) public {
    vm.expectRevert(INifty.Unauthorized.selector);
    callForVoid(sutDatum.sut, alice, abi.encodeWithSignature("reveal(string)", ""));
  }

  function table_reveal_throws_withIncorrectBaseURI(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    callForVoid(
      sut,
      niftyOwner,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256)",
        uint256(keccak256("correct/base/address")),
        "before/reveal/address",
        1 weeks
      )
    );

    vm.expectRevert(IRevealable.WrongPreimage.selector, 2);
    callForVoid(sutDatum.sut, niftyOwner, abi.encodeWithSignature("reveal(string)", ""));
    callForVoid(sutDatum.sut, niftyOwner, abi.encodeWithSignature("reveal(string)", "incorrect/base/address"));
  }

  function table_reveal_succeeds_AndReturnFinalURIWithCorrectProperties(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    callForVoid(
      sut,
      niftyOwner,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256)",
        uint256(keccak256("correct/base/address")),
        "before/reveal/address",
        1 days
      )
    );

    assertEq("before/reveal/address", callForString(sut, user, abi.encodeWithSignature("tokenURI(uint256)", 0)));

    vm.expectEmit();
    emit IRevealable.Revealed("correct/base/address");
    callForVoid(sut, niftyOwner, abi.encodeWithSignature("reveal(string)", "correct/base/address"));

    assertEq("correct/base/address/0.json", callForString(sut, user, abi.encodeWithSignature("tokenURI(uint256)", 0)));
  }

  function table_allTimeLocks_return0_whenCommitRevealPropertiesHasNotBeenCalled(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    assertEq(0, callForUint256(sut, user, abi.encodeWithSignature("revealTimeLockEnd()")));
  }

  function table_allTimeLockEndFunctions_returnsTimeRelativeToBlockTimestamp_whenCommitRevealPropertiesHasBeenCalled(
    SUTDatum memory sutDatum
  ) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    callForVoid(
      sut,
      niftyOwner,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256)",
        uint256(keccak256("correct/base/address")),
        "before/reveal/address",
        123 hours
      )
    );

    assertEq(block.timestamp + 123 hours, callForUint256(sut, user, abi.encodeWithSignature("revealTimeLockEnd()")));
  }
}
