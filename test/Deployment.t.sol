// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";
import { Test } from "forge-std/Test.sol";

contract DeploymentTests is Test {
  Nifty private token;

  function setUp() public {
    token = new Nifty();
  }

  function test_deploy_creatorIsSet() public view {
    assertEq(token.creator(), address(this));
  }
}
