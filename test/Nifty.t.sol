// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Nifty } from "../src/Nifty.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";
import { Test } from "forge-std/Test.sol";

contract NiftyTests is Test, NiftyTestUtils {
  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutDataForNifty();
  }

  function table_initialize_throws_whenImproperlyCalled(SUTDatum memory sutDatum) public {
    expectCallRevert(
      INifty.BadInitialization.selector, sutDatum.sut, niftyOwner, abi.encodeWithSelector(Nifty.initialize.selector, "")
    );
  }
}
