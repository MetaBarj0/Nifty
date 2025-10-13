// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";
import { Test } from "forge-std/Test.sol";

contract NiftyTests is Test, NiftyTestUtils {
  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutDataForCrowdsale();
  }
}
