// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { TransparentUpgradeableProxy } from "../src/proxy/TransparentUpgradeableProxy.sol";
import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

contract DeploymentTests is Test, NiftyTestUtils {
  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_deploy_ownerIsSet(SUTDatum calldata sutDatum) public {
    assertEq(niftyDeployer, callForAddress(sutDatum.sut, sutDatum.user, abi.encodeWithSignature("owner()")));
  }
}
