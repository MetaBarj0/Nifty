// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Nifty } from "../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { TransparentUpgradeableProxy } from "../src/proxy/TransparentUpgradeableProxy.sol";
import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract DeploymentTests is Test, NiftyTestUtils {
  address alice;

  struct SUTDatum {
    address sut;
    address user;
  }

  function setUp() public {
    nifty = new Nifty();
    proxy = new TransparentUpgradeableProxy(address(nifty), "");

    alice = makeAddr("alice");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    SUTDatum[] memory sutData = new SUTDatum[](2);
    sutData[0].sut = address(nifty);
    sutData[0].user = address(this);
    sutData[1].sut = address(proxy);
    sutData[1].user = alice;

    return sutData;
  }

  function table_deploy_creatorIsSet(SUTDatum calldata sutDatum) public {
    vm.startPrank(sutDatum.user);
    (bool success, bytes memory data) = sutDatum.sut.call(abi.encodeWithSignature("creator()"));
    vm.stopPrank();

    assertTrue(success);
    assertEq(address(this), abi.decode(data, (address)));
  }
}
