// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { IERC721Withdrawable } from "../src/interfaces/IERC721Withdrawable.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { Nifty } from "../src/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "./NiftyTestUtils.sol";

contract ERC721WithdrwableTests is Test, NiftyTestUtils {
  address private alice;
  address private bob;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function test_withdraw_throws_ifNotCalledByOwner() public {
    vm.startPrank(alice);

    vm.expectRevert(INifty.Unauthorized.selector);
    nifty.withdraw();

    vm.stopPrank();
  }

  function test_withdraw_throws_ifPaymentFails() public {
    paidMint(alice, 0);

    // There is no receive function in this testing contract
    vm.expectRevert(IERC721Withdrawable.TransferFailed.selector);
    nifty.withdraw();
  }

  function test_withdraw_succeeds_ifCalledByOwner() public {
    uint256 revenuesInContractBeforeMint = address(nifty).balance;

    paidMint(alice, 0);
    paidMint(alice, 1);
    paidMint(alice, 2);

    // transfers ownership from this test contract to bob
    nifty.transferOwnership(bob);
    vm.startPrank(bob);
    nifty.acceptOwnership();
    vm.stopPrank();

    uint256 revenuesInContractAfterMint = address(nifty).balance;

    vm.startPrank(bob);
    nifty.withdraw();
    vm.stopPrank();

    assertEq(revenuesInContractBeforeMint, 0);
    assertGt(revenuesInContractAfterMint, 0);
    assertEq(address(bob).balance, revenuesInContractAfterMint);
    assertEq(address(nifty).balance, 0);
  }
}
