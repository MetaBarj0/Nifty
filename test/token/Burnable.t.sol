// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IERC721 } from "../../src/interfaces/token/IERC721.sol";

import { INifty } from "../../src/interfaces/INifty.sol";

import { Test, console } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract BurnableTests is Test, NiftyTestUtils {
  address private bob;
  address private alice;

  function setUp() public {
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_burn_throw_forNotMintedToken(SUTDatum calldata sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    expectCallRevert(INifty.InvalidTokenId.selector, sut, user, abi.encodeWithSignature("burn(uint256)", 0));
  }

  function table_burn_throws_forExistingTokenNotOwnedBySender(SUTDatum calldata sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sutDatum.sut, alice, 0);

    expectCallRevert(INifty.Unauthorized.selector, sut, user, abi.encodeWithSignature("burn(uint256)", 0));
  }

  function table_burn_succeeds_decreasingTotalSupply(SUTDatum calldata sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);
    paidMintNew(sut, alice, 1);

    uint256 supplyBeforeBurn = callForUint256(sut, user, abi.encodeWithSignature("totalSupply()"));
    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 1));

    assertCallEq(1, sut, alice, abi.encodeWithSignature("totalSupply()"));
    assertEq(2, supplyBeforeBurn);
  }

  function table_burn_succeeds_atRemovingTokenOwnership(SUTDatum calldata sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sutDatum.sut, alice, 0);

    address token0OwnerBeforeBurn = callForAddress(sut, alice, abi.encodeWithSignature("ownerOf(uint256)", 0));

    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 0));

    assertEq(token0OwnerBeforeBurn, alice);
    expectCallRevert(INifty.InvalidTokenId.selector, sut, user, abi.encodeWithSignature("ownerOf(uint256)", 0));
  }

  function table_burn_succeeds_atDecreasingOwnerBalance(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);
    uint256 balanceBeforeBurn = callForUint256(sut, alice, abi.encodeWithSignature("balanceOf(address)", alice));

    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 0));

    assertEq(1, balanceBeforeBurn);
    assertEq(0, callForUint256(sut, alice, abi.encodeWithSignature("balanceOf(address)", alice)));
  }

  function table_burn_succeeds_atRemovingBurntTokenApproval(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);
    callForVoid(sut, alice, abi.encodeWithSignature("approve(address,uint256)", bob, 0));
    address approvedBeforeBurn = callForAddress(sut, user, abi.encodeWithSignature("getApproved(uint256)", 0));
    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 0));

    assertEq(bob, approvedBeforeBurn);
    expectCallRevert(INifty.InvalidTokenId.selector, sut, user, abi.encodeWithSignature("getApproved(uint256)", 0));
  }

  function table_burn_succeeds_ifQueriedByApprovedAddress(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);

    callForVoid(sut, alice, abi.encodeWithSignature("approve(address,uint256)", bob, 0));

    vm.expectEmit();
    emit IERC721.Transfer(bob, address(0), 0);
    callForVoid(sut, bob, abi.encodeWithSignature("burn(uint256)", 0));
  }

  function table_burn_succeeds_ifQueriedByOperator(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);

    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", bob, true));

    vm.expectEmit();
    emit IERC721.Transfer(bob, address(0), 0);
    callForVoid(sut, bob, abi.encodeWithSignature("burn(uint256)", 0));
  }

  function table_burn_emitsTransferEvent_ifQueriedByOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 3);

    vm.expectEmit();
    emit IERC721.Transfer(alice, address(0), 3);
    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 3));
  }
}
