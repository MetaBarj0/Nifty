// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IERC721 } from "../src/interfaces/token/IERC721.sol";
import { INifty } from "../src/interfaces/token/INifty.sol";

import { Nifty } from "../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

contract Ownable2StepsTests is Test, NiftyTestUtils {
  address private bob;
  address private alice;

  function setUp() public {
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_transferOwnership_throws_ifNotCurrentOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    expectCallRevert(
      INifty.Unauthorized.selector, sut, alice, abi.encodeWithSignature("transferOwnership(address)", alice)
    );
  }

  function table_transferOwnership_succeeds_ifCurrentOwner(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    address oldPendingOwner = callForAddress(sut, user, abi.encodeWithSignature("pendingOwner()"));

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("transferOwnership(address)", alice));

    assertEq(address(0), oldPendingOwner);
    assertEq(niftyDeployer, callForAddress(sut, user, abi.encodeWithSignature("owner()")));
    assertEq(alice, callForAddress(sut, user, abi.encodeWithSignature("pendingOwner()")));
  }

  function table_acceptOwnership_throws_ifPendingOwnerIsNotSender(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    expectCallRevert(INifty.Unauthorized.selector, sut, alice, abi.encodeWithSignature("acceptOwnership()"));
  }

  function table_acceptOwnership_succeeds_ifPendingOwnerIsSender(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    address ownerBeforeOwnershipTransfer = callForAddress(sut, user, abi.encodeWithSignature("owner()"));

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("transferOwnership(address)", alice));

    address ownerBeforeAccept = callForAddress(sut, user, abi.encodeWithSignature("owner()"));
    address pendingOwnerBeforeAccept = callForAddress(sut, user, abi.encodeWithSignature("pendingOwner()"));

    callForVoid(sut, alice, abi.encodeWithSignature("acceptOwnership()"));

    assertEq(ownerBeforeOwnershipTransfer, niftyDeployer);
    assertEq(niftyDeployer, ownerBeforeAccept);
    assertEq(alice, callForAddress(sut, user, abi.encodeWithSignature("owner()")));
    assertEq(alice, pendingOwnerBeforeAccept);
    assertEq(address(0), callForAddress(sut, user, abi.encodeWithSignature("pendingOwner()")));
  }

  function table_renounceOwnership_throws_ifNotOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    expectCallRevert(INifty.Unauthorized.selector, sut, alice, abi.encodeWithSignature("renounceOwnership()"));
  }

  function table_renounceOwnership_throws_ifOwnerAndPendingOwnerSet(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("transferOwnership(address)", alice));

    expectCallRevert(INifty.Unauthorized.selector, sut, niftyDeployer, abi.encodeWithSignature("renounceOwnership()"));
  }

  function table_renounceOwnership_succeeds_ifOwnerAndNoPendingOwner(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    address oldOwner = callForAddress(sut, user, abi.encodeWithSignature("owner()"));

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("transferOwnership(address)", alice));
    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("transferOwnership(address)", address(0)));
    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("renounceOwnership()"));

    assertEq(niftyDeployer, oldOwner);
    assertEq(address(0), callForAddress(sut, user, abi.encodeWithSignature("owner()")));
  }
}
