// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { TransparentUpgradeableProxy } from "../src/proxy/TransparentUpgradeableProxy.sol";
import { Nifty } from "../src/token/Nifty.sol";

struct SUTDatum {
  address sut;
  address user;
}

abstract contract NiftyTestUtils is Test {
  Nifty internal nifty;
  TransparentUpgradeableProxy internal proxy;

  address internal niftyDeployer;
  address internal proxyUser;

  constructor() {
    niftyDeployer = makeAddr("niftyDeployer");
    proxyUser = makeAddr("proxyUser");

    vm.startPrank(niftyDeployer);
    nifty = new Nifty();
    vm.stopPrank();

    proxy = new TransparentUpgradeableProxy(address(nifty), abi.encode(niftyDeployer));
  }

  function getSutData() internal view returns (SUTDatum[] memory) {
    SUTDatum[] memory sutData = new SUTDatum[](2);
    sutData[0].sut = address(nifty);
    sutData[0].user = niftyDeployer;
    sutData[1].sut = address(proxy);
    sutData[1].user = proxyUser;

    return sutData;
  }

  function paidMintNew(address sut, address to, uint256 tokenId) internal {
    vm.deal(to, 500 gwei);

    // the to account pays for his token
    vm.startPrank(to);

    (bool success,) = sut.call{ value: 500 gwei }(abi.encodeWithSignature("mint(address,uint256)", to, tokenId));
    require(success);

    vm.stopPrank();
  }

  function assertCallTrue(address sut, address sender, bytes memory callData) internal {
    vm.startPrank(sender);
    (bool success, bytes memory data) = sut.call(callData);
    assertTrue(success);
    assertTrue(abi.decode(data, (bool)));
    vm.stopPrank();
  }

  function assertCallEq(uint256 expected, address sut, address sender, bytes memory callData) internal {
    vm.startPrank(sender);
    (bool success, bytes memory data) = sut.call(callData);
    assertTrue(success);
    assertEq(expected, abi.decode(data, (uint256)));
    vm.stopPrank();
  }

  function expectCallRevert(bytes4 errorSelector, address sut, address sender, bytes memory callData) internal {
    vm.startPrank(sender);
    vm.expectRevert(errorSelector);
    (bool success,) = sut.call(callData);
    assertTrue(success);
    vm.stopPrank();
  }

  function justCall(address sut, address sender, bytes memory callData) private returns (bytes memory) {
    vm.startPrank(sender);
    (bool success, bytes memory data) = sut.call(callData);
    require(success);
    vm.stopPrank();

    return data;
  }

  function callForVoid(address sut, address sender, bytes memory callData) internal {
    justCall(sut, sender, callData);
  }

  function callForUint256(address sut, address sender, bytes memory callData) internal returns (uint256) {
    bytes memory data = justCall(sut, sender, callData);

    return abi.decode(data, (uint256));
  }

  function callForAddress(address sut, address sender, bytes memory callData) internal returns (address) {
    bytes memory data = justCall(sut, sender, callData);

    return abi.decode(data, (address));
  }

  function callForString(address sut, address sender, bytes memory callData) internal returns (string memory) {
    bytes memory data = justCall(sut, sender, callData);

    return abi.decode(data, (string));
  }

  function callForBool(address sut, address sender, bytes memory callData) internal returns (bool) {
    bytes memory data = justCall(sut, sender, callData);

    return abi.decode(data, (bool));
  }
}
