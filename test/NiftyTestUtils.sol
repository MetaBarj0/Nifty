// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ICrowdsaleable } from "../src/interfaces/ICrowdsaleable.sol";
import { INifty } from "../src/interfaces/INifty.sol";
import { ITransparentUpgradeableProxy } from "../src/interfaces/proxy/ITransparentUpgradeableProxy.sol";

import { Crowdsale } from "../src/Crowdsale.sol";
import { Nifty } from "../src/Nifty.sol";
import { TransparentUpgradeableProxy } from "../src/proxy/TransparentUpgradeableProxy.sol";

import { Test } from "forge-std/Test.sol";

struct SUTDatum {
  address sut;
  address user;
}

abstract contract NiftyTestUtils is Test {
  INifty internal nifty;
  ITransparentUpgradeableProxy internal niftyProxy;
  ICrowdsaleable internal crowdsale;
  ITransparentUpgradeableProxy internal crowdsaleProxy;

  address internal niftyOwner;
  address internal crowdsaleOwner;
  address internal niftyProxyUser;
  address internal crowdsaleProxyUser;

  constructor() {
    niftyOwner = makeAddr("niftyOwner");
    niftyProxyUser = makeAddr("niftyProxyUser");
    crowdsaleOwner = makeAddr("crowdsaleOwner");
    crowdsaleProxyUser = makeAddr("crowdsaleProxyUser");

    vm.startPrank(niftyOwner);
    nifty = new Nifty();
    vm.stopPrank();

    vm.startPrank(crowdsaleOwner);
    crowdsale = new Crowdsale(address(nifty));
    vm.stopPrank();

    niftyProxy =
      new TransparentUpgradeableProxy(address(nifty), abi.encodeWithSelector(Nifty.initialize.selector, niftyOwner));
    crowdsaleProxy = new TransparentUpgradeableProxy(
      address(crowdsale), abi.encodeWithSelector(Crowdsale.initialize.selector, crowdsaleOwner, address(nifty))
    );

    vm.startPrank(niftyOwner);
    nifty.authorizeMinter(address(crowdsale), true);
    nifty.authorizeMinter(address(crowdsaleProxy), true);
    vm.stopPrank();
  }

  function testGetSutDataForNifty() internal view returns (SUTDatum[] memory) {
    SUTDatum[] memory sutData = new SUTDatum[](2);
    sutData[0].sut = address(nifty);
    sutData[0].user = niftyOwner;
    sutData[1].sut = address(niftyProxy);
    sutData[1].user = niftyProxyUser;

    return sutData;
  }

  function testGetSutDataForCrowdsale() internal view returns (SUTDatum[] memory) {
    SUTDatum[] memory sutData = new SUTDatum[](2);
    sutData[0].sut = address(crowdsale);
    sutData[0].user = crowdsaleOwner;
    sutData[1].sut = address(crowdsaleProxy);
    sutData[1].user = crowdsaleProxyUser;

    return sutData;
  }

  function authorizeMinter(address sut, address minter, bool authorized) internal {
    vm.startPrank(niftyOwner);

    (bool success,) = sut.call(abi.encodeWithSignature("authorizeMinter(address,bool)", minter, authorized));
    require(success);

    vm.stopPrank();
  }

  function paidMint(address sut, address to, uint256 tokenId) internal {
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

  function expectPaidCallRevert(bytes4 errorSelector, uint256 value, address sut, address sender, bytes memory callData)
    internal
  {
    vm.startPrank(sender);
    vm.expectRevert(errorSelector);
    (bool success,) = sut.call{ value: value }(callData);
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

  function callForBytes4(address sut, address sender, bytes memory callData) internal returns (bytes4) {
    bytes memory data = justCall(sut, sender, callData);

    return abi.decode(data, (bytes4));
  }

  function callForCrowdsaleData(address sut, address sender, bytes memory callData)
    internal
    returns (ICrowdsaleable.CrowdsaleData memory)
  {
    bytes memory data = justCall(sut, sender, callData);

    return abi.decode(data, (ICrowdsaleable.CrowdsaleData));
  }

  function justPaidCall(address sut, address sender, uint256 value, bytes memory callData)
    private
    returns (bytes memory)
  {
    vm.startPrank(sender);
    (bool success, bytes memory data) = sut.call{ value: value }(callData);
    require(success);
    vm.stopPrank();

    return data;
  }

  function paidCallForUint256(address sut, address sender, uint256 value, bytes memory callData)
    internal
    returns (uint256)
  {
    bytes memory data = justPaidCall(sut, sender, value, callData);

    return abi.decode(data, (uint256));
  }
}
