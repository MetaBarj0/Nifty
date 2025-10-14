// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IOwnable2Steps } from "../src/interfaces/IOwnable2Steps.sol";

import { Nifty } from "../src/Nifty.sol";
import { TransparentUpgradeableProxy } from "../src/proxy/TransparentUpgradeableProxy.sol";

import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

contract DeploymentTests is NiftyTestUtils {
  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return testGetSutDataForNifty();
  }

  function test_deploy_emitsAnOwnerChangedEvent() public {
    vm.expectEmit();
    emit IOwnable2Steps.OwnerChanged(address(0), address(this));
    new Nifty();
  }

  function test_initializationThroughTransparentProxy_emitsAnOwnerChangedEvent() public {
    vm.expectEmit();
    emit IOwnable2Steps.OwnerChanged(address(0), address(this));
    new TransparentUpgradeableProxy(address(nifty), abi.encodeWithSelector(Nifty.initialize.selector, address(this)));
  }

  function table_deploy_ownerIsSet(SUTDatum calldata sutDatum) public {
    assertEq(niftyOwner, callForAddress(sutDatum.sut, sutDatum.user, abi.encodeWithSignature("owner()")));
  }
}
