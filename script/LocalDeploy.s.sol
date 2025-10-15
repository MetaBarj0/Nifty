// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ICrowdsaleable } from "../src/interfaces/ICrowdsaleable.sol";
import { INifty } from "../src/interfaces/INifty.sol";
import { ITransparentUpgradeableProxy } from "../src/interfaces/proxy/ITransparentUpgradeableProxy.sol";

import { Crowdsale } from "../src/Crowdsale.sol";
import { Nifty } from "../src/Nifty.sol";
import { TransparentUpgradeableProxy } from "../src/proxy/TransparentUpgradeableProxy.sol";

import { Script } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract LocalDeployScript is Script {
  INifty private nifty;
  ITransparentUpgradeableProxy private niftyProxy;
  ICrowdsaleable private crowdsale;
  ITransparentUpgradeableProxy private crowdsaleProxy;

  address private sender;
  address private niftyOwner;
  address private crowdsaleOwner;

  function setUp() public {
    sender = vm.envAddress("TEST_SENDER_ADDRESS");
    niftyOwner = vm.addr(uint256(vm.envBytes32("TEST_PRIVATE_KEY_01")));
    crowdsaleOwner = vm.addr(uint256(vm.envBytes32("TEST_PRIVATE_KEY_02")));
  }

  function run() public {
    vm.startBroadcast(niftyOwner);
    nifty = new Nifty();
    vm.stopBroadcast();

    vm.startBroadcast(crowdsaleOwner);
    crowdsale = new Crowdsale(address(nifty));
    vm.stopBroadcast();

    vm.startBroadcast();

    niftyProxy =
      new TransparentUpgradeableProxy(address(nifty), abi.encodeWithSelector(Nifty.initialize.selector, niftyOwner));
    crowdsaleProxy = new TransparentUpgradeableProxy(
      address(crowdsale), abi.encodeWithSelector(Crowdsale.initialize.selector, crowdsaleOwner, address(nifty))
    );

    vm.stopBroadcast();

    vm.startBroadcast(niftyOwner);

    nifty.authorizeMinter(address(crowdsale), true);
    nifty.authorizeMinter(address(crowdsaleProxy), true);

    vm.stopBroadcast();
  }

  // NOTE: To mute uncovered items in coverage reports
  function test() private { }
}
