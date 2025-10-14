// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Nifty } from "../src/Nifty.sol";

import { Script } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

// TODO: deploy scripts for Crowdsale and Proxy
contract NiftyLocalDeployScript is Script {
  // NOTE: To mute uncovered items in coverage reports
  function test() public { }

  function setUp() public { }

  function run() public {
    vm.startBroadcast();

    new Nifty();

    vm.stopBroadcast();
  }
}
