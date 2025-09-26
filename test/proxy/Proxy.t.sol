// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ITransparentUpgradeableProxy } from "../../src/interfaces/proxy/ITransparentUpgradeableProxy.sol";
import { TransparentUpgradeableProxy } from "../../src/proxy/TransparentUpgradeableProxy.sol";

import { FailingInitializableImplementation, NotInitializableImplementation, TestImplementation } from "../Mocks.sol";
import { Test } from "forge-std/Test.sol";

contract ProxyTests is Test {
  TestImplementation implementation;
  ITransparentUpgradeableProxy proxy;

  address alice;

  function setUp() public {
    implementation = new TestImplementation();
    proxy = new TransparentUpgradeableProxy(address(implementation), abi.encode(42));

    alice = makeAddr("alice");
  }

  function test_constructor_throws_withZeroImplementation() public {
    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);

    new TransparentUpgradeableProxy(address(0), "");
  }

  function test_constructor_throws_withNotInitializableImplementation() public {
    NotInitializableImplementation notInitializableImplementation = new NotInitializableImplementation();

    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);

    new TransparentUpgradeableProxy(address(notInitializableImplementation), "");
  }

  function test_constructor_throws_withFailingInitializableImplementation() public {
    FailingInitializableImplementation failingInitializableImplementation = new FailingInitializableImplementation();

    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);

    new TransparentUpgradeableProxy(address(failingInitializableImplementation), "");
  }

  function test_constructor_initializesAdminAndImplementation_forAdminAccess() public {
    vm.expectEmit();
    emit ITransparentUpgradeableProxy.ImplementationInitialized();
    proxy = new TransparentUpgradeableProxy(address(implementation), abi.encode(42));

    assertEq(address(this), proxy.admin());
    assertEq(address(implementation), proxy.implementation());
  }

  function test_admin_returnsActualAdmin_ifAdmin() public {
    (bool success, bytes memory data) = address(proxy).call(abi.encodeWithSignature("admin()"));

    assertTrue(success);
    assertEq(address(this), abi.decode(data, (address)));
  }

  function test_implementation_returnsActualImplementation_ifAdmin() public {
    (bool success, bytes memory data) = address(proxy).call(abi.encodeWithSignature("implementation()"));

    assertTrue(success);
    assertEq(address(implementation), abi.decode(data, (address)));
  }

  function test_receive_throws_asUnsupported() public {
    (bool success, bytes memory data) = address(proxy).call{ value: 500 gwei }("");

    assertFalse(success);
    assertEq(ITransparentUpgradeableProxy.ReceiveUnsupported.selector, bytes4(data));
  }

  function test_callforward_throughFallback_ifNotAdmin() public {
    vm.startPrank(alice);

    (bool successAdminCall, bytes memory dataAdminCall) = address(proxy).call(abi.encodeWithSignature("admin()"));
    (bool successImplementationCall, bytes memory dataImplementationCall) =
      address(proxy).call(abi.encodeWithSignature("implementation()"));

    vm.stopPrank();

    assertTrue(successAdminCall);
    assertTrue(successImplementationCall);
    assertEq(abi.decode(dataAdminCall, (string)), implementation.admin());
    assertEq(abi.decode(dataImplementationCall, (string)), implementation.implementation());
  }

  function test_callForward_throwsForUnexistingFunction_forNotAdmin() public {
    vm.startPrank(alice);
    (bool success,) = address(proxy).call(abi.encodeWithSignature("bar()"));
    vm.stopPrank();

    assertFalse(success);
  }

  function test_callForward_throws_forAdmin() public {
    (bool success, bytes memory data) = address(proxy).call(abi.encodeWithSignature("foo()"));

    assertFalse(success);
    assertEq(ITransparentUpgradeableProxy.InvalidAdminCall.selector, bytes4(data));
  }

  function test_stateChangesOccurInProxyStorage_forNotAdminCalls() public {
    vm.startPrank(alice);

    (bool success,) = address(proxy).call(abi.encodeWithSignature("inc()"));
    (, bytes memory data) = address(proxy).call(abi.encodeWithSignature("foo()"));

    vm.stopPrank();

    assertTrue(success);
    assertEq(address(this), proxy.admin());
    assertEq(address(implementation), proxy.implementation());
    assertEq(0, implementation.foo());
    assertEq(43, abi.decode(data, (uint256)));
  }
}
