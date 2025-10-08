// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721Enumerable } from "../../src/interfaces/token/IERC721Enumerable.sol";

import { INifty } from "../../src/interfaces/INifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract ERC721EnumerableTests is Test, NiftyTestUtils {
  address private alice;
  address private bob;
  address private chuck;

  function setUp() public {
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
    chuck = makeAddr("Chuck");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutDataForNifty();
  }

  function table_totalSupply_returns0AtContractInitialization(SUTDatum memory sutDatum) public {
    assertEq(callForUint256(sutDatum.sut, sutDatum.user, abi.encodeWithSignature("totalSupply()")), 0);
  }

  function table_totalSupply_succeeds_atReturningMintedTokenAmount(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    authorizeMinter(sut, bob, true);
    authorizeMinter(sut, chuck, true);

    paidMint(sut, alice, 0);
    paidMint(sut, bob, 1);
    paidMint(sut, chuck, 2);

    assertEq(callForUint256(sut, user, abi.encodeWithSignature("totalSupply()")), 3);
  }

  function table_totalSupply_succeeds_atReturningMintedAndBurntTokenAmount(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);

    paidMint(sut, alice, 0);
    paidMint(sut, alice, 1);

    uint256 balanceBeforeBurn = callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", alice));

    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 1));

    assertEq(balanceBeforeBurn, 2);
    assertEq(callForUint256(sut, user, abi.encodeWithSignature("totalSupply()")), 1);
  }

  function table_tokenByIndex_throws_forIndexGreaterOrEqualThanTotalSupply(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    assertEq(callForUint256(sut, user, abi.encodeWithSignature("totalSupply()")), 0);

    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    callForUint256(sut, user, abi.encodeWithSignature("tokenByIndex(uint256)", 0));

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    callForUint256(sut, user, abi.encodeWithSignature("tokenByIndex(uint256)", 1));
  }

  function table_tokenByIndex_succeeds_forMintedTokens(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    authorizeMinter(sut, bob, true);

    paidMint(sut, alice, 42);
    paidMint(sut, bob, 43);

    assertEq(42, callForUint256(sut, user, abi.encodeWithSignature("tokenByIndex(uint256)", 0)));
    assertEq(43, callForUint256(sut, user, abi.encodeWithSignature("tokenByIndex(uint256)", 1)));
  }

  function table_tokenByIndex_throws_forABurntTokenAtSpecifiedIndex(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    authorizeMinter(sut, bob, true);

    paidMint(sut, alice, 42);
    paidMint(sut, bob, 43);
    paidMint(sut, alice, 44);

    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 42));
    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 44));

    assertEq(43, callForUint256(sut, user, abi.encodeWithSignature("tokenByIndex(uint256)", 0)));

    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    callForUint256(sut, user, abi.encodeWithSignature("tokenByIndex(uint256)", 1));
  }

  function table_tokenOfOwnerByIndex_throws_forIndexGreaterOrEqualToOwnerBalance(SUTDatum memory sutDatum) public {
    vm.expectRevert(IERC721Enumerable.IndexOutOfBound.selector);
    callForUint256(sutDatum.sut, alice, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", alice, 0));
  }

  function table_tokenOfOwnerByIndex_throws_forInvalidToken(SUTDatum memory sutDatum) public {
    vm.expectRevert(INifty.InvalidTokenId.selector);
    callForUint256(
      sutDatum.sut, sutDatum.user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", address(0), 0)
    );
  }

  function table_tokenOfOwnerByIndex_succeeds_forDifferentOwners(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    authorizeMinter(sut, bob, true);

    paidMint(sut, alice, 10);
    paidMint(sut, alice, 11);
    paidMint(sut, bob, 12);
    paidMint(sut, bob, 13);

    assertEq(10, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", alice, 0)));
    assertEq(11, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", alice, 1)));
    assertEq(12, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", bob, 0)));
    assertEq(13, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", bob, 1)));
  }

  function table_tokenOfOwnerByIndex_succeeds_forDifferentOwnersWhoBurn(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    authorizeMinter(sut, bob, true);
    authorizeMinter(sut, chuck, true);

    paidMint(sut, alice, 10);
    paidMint(sut, alice, 11);
    paidMint(sut, alice, 12);
    paidMint(sut, bob, 13);
    paidMint(sut, bob, 14);
    paidMint(sut, bob, 15);
    paidMint(sut, chuck, 16);
    paidMint(sut, chuck, 17);
    paidMint(sut, chuck, 18);

    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 10));
    callForVoid(sut, bob, abi.encodeWithSignature("burn(uint256)", 14));
    callForVoid(sut, chuck, abi.encodeWithSignature("burn(uint256)", 18));

    assertEq(12, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", alice, 0)));
    assertEq(11, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", alice, 1)));

    assertEq(13, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", bob, 0)));
    assertEq(15, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", bob, 1)));

    assertEq(16, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", chuck, 0)));
    assertEq(17, callForUint256(sut, user, abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", chuck, 1)));
  }
}
