// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "../../src/interfaces/INifty.sol";
import { ITransparentUpgradeableProxy } from "../../src/interfaces/proxy/ITransparentUpgradeableProxy.sol";

import { TransparentUpgradeableProxy } from "../../src/proxy/TransparentUpgradeableProxy.sol";

import {
  FailingInitializableImplementation,
  TestImplementation,
  TestNewImplementation,
  TriviallyConstructibleContract
} from "../Mocks.sol";
import { NiftyTestUtils } from "../NiftyTestUtils.sol";

contract ProxyTests is NiftyTestUtils {
  TestImplementation implementation;
  ITransparentUpgradeableProxy proxy;

  address alice;

  function setUp() public {
    implementation = new TestImplementation();
    proxy = new TransparentUpgradeableProxy(
      address(implementation), abi.encodeWithSelector(TestImplementation.initialize.selector, 42)
    );

    alice = makeAddr("alice");
  }

  function test_constructor_throws_withZeroImplementation() public {
    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);
    new TransparentUpgradeableProxy(address(0), "");
  }

  function test_constructor_throws_withFailingInitializableImplementation() public {
    FailingInitializableImplementation failingInitializableImplementation = new FailingInitializableImplementation();

    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);
    new TransparentUpgradeableProxy(
      address(failingInitializableImplementation),
      abi.encodeWithSelector(FailingInitializableImplementation.initialize.selector)
    );
  }

  function test_constructor_initializes_triviallyConstructibleContract() public {
    TriviallyConstructibleContract triviallyConstructibleContract = new TriviallyConstructibleContract();

    vm.expectEmit();
    emit ITransparentUpgradeableProxy.ImplementationInitialized();
    proxy = new TransparentUpgradeableProxy(address(triviallyConstructibleContract), "");

    assertEq(address(this), proxy.admin());
    assertEq(address(triviallyConstructibleContract), proxy.implementation());
  }

  function test_constructor_initializesAdminAndImplementation_forAdminAccess() public {
    vm.expectEmit();
    emit ITransparentUpgradeableProxy.ImplementationInitialized();
    proxy = new TransparentUpgradeableProxy(
      address(implementation), abi.encodeWithSelector(TestImplementation.initialize.selector, 42)
    );

    assertEq(address(this), proxy.admin());
    assertEq(address(implementation), proxy.implementation());
  }

  function test_admin_returnsProxyAdmin_ifAdmin() public {
    assertEq(address(this), callForAddress(address(proxy), address(this), abi.encodeWithSignature("admin()")));
  }

  function test_admin_returnsImplementationAdmin_ifNotAdmin() public {
    assertEq(implementation.admin(), callForAddress(address(proxy), alice, abi.encodeWithSignature("admin()")));
  }

  function test_implementation_returnsProxyImplementation_ifAdmin() public {
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
    (address adminAddress, address implementationAddress) = (
      callForAddress(address(proxy), alice, abi.encodeWithSignature("admin()")),
      callForAddress(address(proxy), alice, abi.encodeWithSignature("implementation()"))
    );

    assertEq(adminAddress, implementation.admin());
    assertEq(implementationAddress, implementation.implementation());
  }

  function test_callForward_throwsForUnexistingFunction_forNotAdmin() public {
    vm.expectRevert();
    callForVoid(address(proxy), alice, abi.encodeWithSignature("baz()"));
  }

  function test_callForward_throws_forAdmin() public {
    expectCallRevert(
      ITransparentUpgradeableProxy.InvalidAdminCall.selector,
      address(proxy),
      address(this),
      abi.encodeWithSignature("foo()")
    );
  }

  function test_stateChangesOccurInProxyStorage_forNotAdminCalls() public {
    callForVoid(address(proxy), alice, abi.encodeWithSignature("inc()"));
    uint256 data = callForUint256(address(proxy), alice, abi.encodeWithSignature("foo()"));

    assertEq(address(this), proxy.admin());
    assertEq(address(implementation), proxy.implementation());
    assertEq(0, implementation.foo());
    assertEq(43, data);
  }

  function test_upgradeToAndCall_throws_ifNotCalledByAdmin() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    proxy.upgradeToAndCall(address(0), "");

    vm.stopPrank();
  }

  function test_upgradeToAndCall_throws_withZeroAddressImplementation() public {
    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);
    proxy.upgradeToAndCall(address(0), "");
  }

  function test_upgradeToAndCall_throws_withEOA() public {
    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);
    proxy.upgradeToAndCall(alice, "");
  }

  function test_upgradeToAndCall_throws_withFailingInitializationContract() public {
    FailingInitializableImplementation f = new FailingInitializableImplementation();

    vm.expectRevert(ITransparentUpgradeableProxy.InvalidImplementation.selector);
    proxy.upgradeToAndCall(address(f), abi.encodeWithSelector(FailingInitializableImplementation.initialize.selector));
  }

  function test_upgradeToAndCall_succeeds_andEmitsWithCorrectNewImplementation() public {
    address oldImplementation = proxy.implementation();
    TestNewImplementation newImplementation = new TestNewImplementation();

    vm.expectEmit();
    emit ITransparentUpgradeableProxy.ImplementationChanged(oldImplementation);
    proxy.upgradeToAndCall(
      address(newImplementation), abi.encodeWithSelector(TestNewImplementation.initialize.selector, 99, 256)
    );

    assertEq(address(newImplementation), proxy.implementation());

    uint256 foo = callForUint256(address(proxy), alice, abi.encodeWithSignature("foo()"));
    assertEq(99, foo);
    assertEq(0, newImplementation.foo());

    uint256 bar = callForUint256(address(proxy), alice, abi.encodeWithSignature("bar()"));
    assertEq(256, bar);
    assertEq(0, newImplementation.bar());
  }
}
