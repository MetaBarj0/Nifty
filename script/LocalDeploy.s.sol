// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import { Nifty } from "../src/Nifty.sol";

import { Script, console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract SepoliaDeployScript is Script {
  function setUp() public { }

  function run() public {
    vm.startBroadcast();

    new Nifty();

    vm.stopBroadcast();
  }
}
