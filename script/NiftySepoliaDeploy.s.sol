// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Nifty } from "../src/Nifty.sol";

import { Script } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract NiftySepoliaDeployScript is Script {
  // NOTE: To mute uncovered items in coverage reports
  function test() private { }

  function setUp() public { }

  function run() public {
    uint256 pk = vm.envUint("PRIVATE_KEY");
    Vm.Wallet memory wallet = vm.createWallet(pk);

    vm.startBroadcast(wallet.privateKey);

    new Nifty();

    vm.stopBroadcast();
  }
}
