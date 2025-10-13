// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IInitializable } from "../src/interfaces/proxy/IInitializable.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";
import { Test } from "forge-std/Test.sol";

contract NiftyTests is Test, NiftyTestUtils {
  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutDataForNifty();
  }

  function table_initialize_throws_whenImproperlyCalled(SUTDatum memory sutDatum) public {
    expectCallRevert(
      IInitializable.ImproperInitialization.selector,
      sutDatum.sut,
      niftyOwner,
      abi.encodeWithSignature("initialize(bytes)", "")
    );
  }
}
