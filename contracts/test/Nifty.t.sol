// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Nifty } from "../src/Nifty.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

contract NiftyTests is NiftyTestUtils {
  address private alice;

  function setUp() public {
    alice = makeAddr("Alice");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return testGetSutDataForNifty();
  }

  function table_initialize_throws_whenImproperlyCalled(SUTDatum memory sutDatum) public {
    expectCallRevert(
      INifty.BadInitialization.selector, sutDatum.sut, niftyOwner, abi.encodeWithSelector(Nifty.initialize.selector, "")
    );
  }

  function table_transferOwnership_fails_whenCurrentOwnerIsAuthorizedMinter(SUTDatum memory sutDatum) public {
    callForVoid(sutDatum.sut, niftyOwner, abi.encodeWithSignature("authorizeMinter(address,bool)", alice, true));

    expectCallRevert(
      INifty.Unauthorized.selector,
      sutDatum.sut,
      niftyOwner,
      abi.encodeWithSignature("transferOwnership(address)", alice)
    );
  }
}
