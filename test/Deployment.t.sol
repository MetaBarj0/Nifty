// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Nifty } from "../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { TransparentUpgradeableProxy } from "../src/proxy/TransparentUpgradeableProxy.sol";
import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract DeploymentTests is Test, NiftyTestUtils {
  address alice;

  function setUp() public {
    nifty = new Nifty();
    proxy = new TransparentUpgradeableProxy(address(nifty), "");

    alice = makeAddr("alice");
    vm.startPrank(alice);
  }

  function test_deploy_creatorIsSet() public {
    (bool implSuccess, bytes memory implData) = address(nifty).call(abi.encodeWithSignature("creator()"));
    (bool proxySuccess, bytes memory proxyData) = address(proxy).call(abi.encodeWithSignature("creator()"));

    assertTrue(implSuccess);
    assertEq(address(this), abi.decode(implData, (address)));

    assertTrue(proxySuccess);
    assertEq(address(this), abi.decode(proxyData, (address)));
  }
}
