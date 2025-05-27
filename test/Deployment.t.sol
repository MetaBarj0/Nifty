// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract DeploymentTests is Test, NiftyTestUtils {
  function setUp() public {
    nifty = new Nifty();
  }

  function test_deploy_creatorIsSet() public view {
    assertEq(nifty.creator(), address(this));
  }
}
