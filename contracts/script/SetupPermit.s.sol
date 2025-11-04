// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "../src/interfaces/INifty.sol";

import { Nifty } from "../src/Nifty.sol";

import { Script } from "forge-std/Script.sol";

contract SetupPermit is Script {
  INifty private nifty;
  address private alice;
  address private niftyOwner;

  function setUp() public {
    alice = vm.addr(uint256(vm.envBytes32("TEST_PRIVATE_KEY_01")));
    niftyOwner = vm.addr(uint256(vm.envBytes32("TEST_PRIVATE_KEY_03")));
  }

  function run() public {
    vm.startBroadcast(niftyOwner);
    nifty = new Nifty();
    nifty.authorizeMinter(alice, true);
    vm.stopBroadcast();

    vm.startBroadcast(alice);
    nifty.mint(alice, 0);
    vm.stopBroadcast();
  }

  // NOTE: To mute uncovered items in coverage reports
  function test() private { }
}
