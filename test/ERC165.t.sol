// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";
import { IERC165 } from "../src/interfaces/IERC165.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { Test } from "forge-std/Test.sol";

contract DeploymentTests is Test {
  Nifty private nifty;

  function setUp() public {
    nifty = new Nifty();
  }

  function test_supports_interface() public view {
    assertEq(nifty.supportsInterface(type(IERC165).interfaceId), true);
    assertEq(nifty.supportsInterface(type(INifty).interfaceId), true);
  }
}
