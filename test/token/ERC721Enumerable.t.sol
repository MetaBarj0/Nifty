// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721Enumerable } from "../../src/interfaces/token/IERC721Enumerable.sol";
import { INifty } from "../../src/interfaces/token/INifty.sol";

import { Nifty } from "../../src/token/Nifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils } from "../NiftyTestUtils.sol";

contract ERC721EnumerableTests is Test, NiftyTestUtils {
  address private alice;
  address private bob;
  address private chuck;

  function setUp() public {
    nifty = new Nifty();

    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
    chuck = makeAddr("Chuck");
  }

  function test_totalSupply_returns0AtContractInitialization() public view {
    assertEq(nifty.totalSupply(), 0);
  }

  function test_totalSupply_succeeds_atReturningMintedTokenAmount() public {
    paidMint(alice, 0);
    paidMint(bob, 1);
    paidMint(chuck, 2);

    assertEq(nifty.totalSupply(), 3);
  }

  function test_totalSupply_succeeds_atReturningMintedAndBurntTokenAmount() public {
    paidMint(alice, 0);
    paidMint(alice, 1);
    uint256 balanceBeforeBurn = nifty.balanceOf(alice);

    vm.startPrank(alice);
    nifty.burn(1);
    vm.stopPrank();

    assertEq(balanceBeforeBurn, 2);
    assertEq(nifty.totalSupply(), 1);
  }

  function test_tokenByIndex_throws_forIndexGreaterOrEqualThanTotalSupply() public {
    assertEq(nifty.totalSupply(), 0);
    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    nifty.tokenByIndex(0);

    paidMint(alice, 0);
    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    nifty.tokenByIndex(1);
  }

  function test_tokenByIndex_succeeds_forMintedTokens() public {
    paidMint(alice, 42);
    paidMint(bob, 43);

    assertEq(42, nifty.tokenByIndex(0));
    assertEq(43, nifty.tokenByIndex(1));
  }

  function test_tokenByIndex_throws_forABurntTokenAtSpecifiedIndex() public {
    paidMint(alice, 42);
    paidMint(bob, 43);
    paidMint(alice, 44);

    vm.startPrank(alice);
    nifty.burn(42);
    nifty.burn(44);
    vm.stopPrank();

    assertEq(43, nifty.tokenByIndex(0));

    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    nifty.tokenByIndex(1);
  }

  function test_tokenOfOwnerByIndex_throws_forIndexGreaterOrEqualToOwnerBalance() public {
    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    nifty.tokenOfOwnerByIndex(alice, 0);
  }

  function test_tokenOfOwnerByIndex_throws_forInvalidToken() public {
    vm.expectRevert(INifty.InvalidTokenId.selector);
    nifty.tokenOfOwnerByIndex(address(0), 0);
  }

  function test_tokenOfOwnerByIndex_succeeds_forDifferentOwners() public {
    paidMint(alice, 10);
    paidMint(alice, 11);
    paidMint(bob, 12);
    paidMint(bob, 13);

    assertEq(10, nifty.tokenOfOwnerByIndex(alice, 0));
    assertEq(11, nifty.tokenOfOwnerByIndex(alice, 1));
    assertEq(12, nifty.tokenOfOwnerByIndex(bob, 0));
    assertEq(13, nifty.tokenOfOwnerByIndex(bob, 1));
  }

  function test_tokenOfOwnerByIndex_succeeds_forDifferentOwnersWhoBurn() public {
    paidMint(alice, 10);
    paidMint(alice, 11);
    paidMint(alice, 12);
    paidMint(bob, 13);
    paidMint(bob, 14);
    paidMint(bob, 15);
    paidMint(chuck, 16);
    paidMint(chuck, 17);
    paidMint(chuck, 18);

    vm.startPrank(alice);
    nifty.burn(10);
    vm.stopPrank();

    vm.startPrank(bob);
    nifty.burn(14);
    vm.stopPrank();

    vm.startPrank(chuck);
    nifty.burn(18);
    vm.stopPrank();

    assertEq(12, nifty.tokenOfOwnerByIndex(alice, 0));
    assertEq(11, nifty.tokenOfOwnerByIndex(alice, 1));

    assertEq(13, nifty.tokenOfOwnerByIndex(bob, 0));
    assertEq(15, nifty.tokenOfOwnerByIndex(bob, 1));

    assertEq(16, nifty.tokenOfOwnerByIndex(chuck, 0));
    assertEq(17, nifty.tokenOfOwnerByIndex(chuck, 1));
  }
}
