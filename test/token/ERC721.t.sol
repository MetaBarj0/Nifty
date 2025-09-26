// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721 } from "../../src/interfaces/token/IERC721.sol";

import { INifty } from "../../src/interfaces/INifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract ERC721Tests is Test, NiftyTestUtils {
  address private alice;
  address private bob;
  address private chuck;
  address private david;

  function setUp() public {
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
    chuck = makeAddr("Chuck");
    david = makeAddr("David");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_balanceOf_returns0_forUserHavingNoToken(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    assertEq(0, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", bob)));
  }

  function table_balanceOf_succeeds_returnsUserBalance(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    for (uint256 index = 0; index < 42; index++) {
      paidMintNew(sut, alice, index);
    }

    assertEq(42, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", alice)));
  }

  function table_ownerOf_throws_forUnmintedTokens(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    expectCallRevert(INifty.InvalidTokenId.selector, sut, user, abi.encodeWithSignature("ownerOf(uint256)", 42));
  }

  function table_getApprove_throws_forInvalidToken(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    expectCallRevert(INifty.InvalidTokenId.selector, sut, user, abi.encodeWithSignature("getApproved(uint256)", 0));
  }

  function table_approve_throws_ifSenderIsNotOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);

    expectCallRevert(
      INifty.Unauthorized.selector, sut, bob, abi.encodeWithSignature("approve(address,uint256)", chuck, 0)
    );
  }

  function table_approve_succeeds_ifSenderIsOwner(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);

    vm.expectEmit();
    emit IERC721.Approval(alice, bob, 0);
    callForVoid(sut, alice, abi.encodeWithSignature("approve(address,uint256)", bob, 0));

    assertEq(bob, callForAddress(sut, user, abi.encodeWithSignature("getApproved(uint256)", 0)));
  }

  function table_setApprovalForAll_succeeds_andEmitApprovalForAll(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);
    paidMintNew(sut, alice, 1);

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, bob, true);
    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", bob, true));

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, chuck, true);
    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", chuck, true));

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, bob, false);
    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", bob, false));

    vm.expectEmit();
    emit IERC721.ApprovalForAll(alice, chuck, false);
    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", chuck, false));
  }

  function table_isApprovedForAll_succeeds_andProvesSeveralOperatorsSupportForOwner(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);

    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", bob, true));
    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", chuck, true));

    assertTrue(callForBool(sut, user, abi.encodeWithSignature("isApprovedForAll(address,address)", alice, bob)));
    assertTrue(callForBool(sut, user, abi.encodeWithSignature("isApprovedForAll(address,address)", alice, chuck)));

    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", bob, false));
    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", chuck, false));

    assertFalse(callForBool(sut, user, abi.encodeWithSignature("isApprovedForAll(address,address)", alice, bob)));
    assertFalse(callForBool(sut, user, abi.encodeWithSignature("isApprovedForAll(address,address)", alice, chuck)));
    assertFalse(callForBool(sut, user, abi.encodeWithSignature("isApprovedForAll(address,address)", alice, david)));
  }

  function table_approve_throws_ifSenderIsNotOperator(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);

    expectCallRevert(
      INifty.Unauthorized.selector, sut, bob, abi.encodeWithSignature("approve(address,uint256)", chuck, 0)
    );
  }

  function table_approve_succeeds_ifSenderisOperator(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);

    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", chuck, true));

    vm.expectEmit();
    emit IERC721.Approval(alice, bob, 0);
    callForVoid(sut, chuck, abi.encodeWithSignature("approve(address,uint256)", bob, 0));
  }

  function table_transferFrom_throws_unsafeTransferFromIsUnsupported(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);

    expectCallRevert(
      INifty.Unsupported.selector,
      sut,
      alice,
      abi.encodeWithSignature("transferFrom(address,address,uint256)", alice, bob, 0)
    );
  }

  function table_safeTransferFrom_throws_ifNotOwnerNorApprovedNorOperator(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 0);

    expectCallRevert(
      INifty.Unauthorized.selector,
      sut,
      bob,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", bob, chuck, 0)
    );

    expectCallRevert(
      INifty.Unauthorized.selector,
      sut,
      bob,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, chuck, 0)
    );
  }

  function table_safeTransferFrom_throws_ifFromIsNotTheCurrentOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 1);

    expectCallRevert(
      INifty.Unauthorized.selector,
      sut,
      alice,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", bob, chuck, 1)
    );
  }

  function table_safeTransferFrom_throws_ifToIsZeroAddress(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    paidMintNew(sut, alice, 1);

    expectCallRevert(
      INifty.ZeroAddress.selector,
      sut,
      alice,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, address(0), 1)
    );
  }

  function table_safeTransferFrom_throws_ifTokenIsInvalid(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    expectCallRevert(
      INifty.InvalidTokenId.selector,
      sut,
      user,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, bob, 0)
    );
  }

  function table_safeTransferFrom_succeeds_ifOwner(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);

    vm.expectEmit();
    emit IERC721.Transfer(alice, bob, 0);
    callForVoid(sut, alice, abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, bob, 0));

    assertEq(0, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", alice)));
    assertEq(1, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", bob)));
    assertEq(bob, callForAddress(sut, user, abi.encodeWithSignature("ownerOf(uint256)", 0)));
  }

  function table_safeTransferFrom_succeeds_ifApproved(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);

    callForVoid(sut, alice, abi.encodeWithSignature("approve(address,uint256)", bob, 0));

    vm.expectEmit();
    emit IERC721.Transfer(alice, chuck, 0);
    callForVoid(sut, bob, abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, chuck, 0));

    assertEq(0, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", alice)));
    assertEq(0, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", bob)));
    assertEq(1, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", chuck)));
    assertEq(chuck, callForAddress(sut, user, abi.encodeWithSignature("ownerOf(uint256)", 0)));
  }

  function table_safeTransferFrom_succeeds_ifOperator(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);
    paidMintNew(sut, alice, 1);

    callForVoid(sut, alice, abi.encodeWithSignature("setApprovalForAll(address,bool)", bob, true));

    vm.expectEmit();
    emit IERC721.Transfer(alice, chuck, 0);
    callForVoid(sut, bob, abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, chuck, 0));

    vm.expectEmit();
    emit IERC721.Transfer(alice, chuck, 1);
    callForVoid(sut, bob, abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, chuck, 1));

    assertEq(0, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", alice)));
    assertEq(0, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", bob)));
    assertEq(2, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", chuck)));
    assertEq(chuck, callForAddress(sut, user, abi.encodeWithSignature("ownerOf(uint256)", 0)));
    assertEq(chuck, callForAddress(sut, user, abi.encodeWithSignature("ownerOf(uint256)", 1)));
  }

  function table_safeTransferFrom_succeeds_andResetApproval(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);

    callForVoid(sut, alice, abi.encodeWithSignature("approve(address,uint256)", bob, 0));

    assertEq(bob, callForAddress(sut, user, abi.encodeWithSignature("getApproved(uint256)", 0)));

    callForVoid(sut, alice, abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, chuck, 0));

    assertEq(address(0), callForAddress(sut, user, abi.encodeWithSignature("getApproved(uint256)", 0)));
  }
}
