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

contract SepoliaDeployScript is Script {
  Vm.Wallet private wallet;

  INifty private nifty;
  ITransparentUpgradeableProxy private niftyProxy;
  ICrowdsaleable private crowdsale;
  ITransparentUpgradeableProxy private crowdsaleProxy;

  function setUp() public {
    uint256 pk = vm.envUint("PRIVATE_KEY");
    wallet = vm.createWallet(pk);
  }

  function run() public {
    vm.startBroadcast(wallet.privateKey);
    nifty = new Nifty();
    crowdsale = new Crowdsale(address(nifty));

    niftyProxy =
      new TransparentUpgradeableProxy(address(nifty), abi.encodeWithSelector(Nifty.initialize.selector, wallet.addr));
    crowdsaleProxy = new TransparentUpgradeableProxy(
      address(crowdsale), abi.encodeWithSelector(Crowdsale.initialize.selector, wallet.addr, address(nifty))
    );

    nifty.authorizeMinter(address(crowdsale), true);
    nifty.authorizeMinter(address(crowdsaleProxy), true);

    vm.stopBroadcast();
  }

  // NOTE: To mute uncovered items in coverage reports
  function test() private { }
}
