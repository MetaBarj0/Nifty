// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721 } from "../../src/interfaces/token/IERC721.sol";
import { IERC721Permit } from "../../src/interfaces/token/IERC721Permit.sol";

import { INifty } from "../../src/interfaces/INifty.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract ERC721Tests is NiftyTestUtils {
  address private alice;
  uint256 private aliceKey;
  address private bob;

  function setUp() public {
    (alice, aliceKey) = makeAddrAndKey("Alice");
    bob = makeAddr("Bob");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return testGetSutDataForNifty();
  }

  function table_permit_throws_withExpiredDeadline(SUTDatum memory sutDatum) public {
    uint256 deadline = block.timestamp + 10 minutes;

    (uint8 v, bytes32 r, bytes32 s) = getPermitSignature_(aliceKey, alice, bob, 0, deadline, 0);

    skip(20 minutes);

    expectCallRevert(
      IERC721Permit.DeadlineExpired.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)", alice, bob, 0, deadline, 0, v, r, s
      )
    );
  }

  function table_permit_throws_withInvalidNonce(SUTDatum memory sutDatum) public {
    uint256 deadline = block.timestamp + 10 minutes;

    (uint8 v, bytes32 r, bytes32 s) = getPermitSignature_(aliceKey, alice, bob, 0, deadline, 123);

    expectCallRevert(
      IERC721Permit.InvalidNonce.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)", alice, bob, 0, deadline, 123, v, r, s
      )
    );
  }

  function table_permit_throws_withIncorrectRecoveredAddress(SUTDatum memory sutDatum) public {
    uint256 deadline = block.timestamp + 10 minutes;

    (uint8 v, bytes32 r, bytes32 s) = getPermitSignature_(aliceKey, alice, bob, 0, deadline, 0);

    expectCallRevert(
      IERC721Permit.InvalidSigner.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)",
        bob, // swapped owner and spender
        alice,
        0,
        deadline,
        0,
        v,
        r,
        s
      )
    );
  }

  function table_throws_forNotOwnedToken(SUTDatum memory sutDatum) public {
    uint256 deadline = block.timestamp + 10 minutes;

    (uint8 v, bytes32 r, bytes32 s) = getPermitSignature_(aliceKey, alice, bob, 0, deadline, 0);

    expectCallRevert(
      INifty.Unauthorized.selector,
      sutDatum.sut,
      bob,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)", alice, bob, 0, deadline, 0, v, r, s
      )
    );
  }

  function table_permit_emits_Approve_andUpdateNonces_onSuccess(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    assertEq(0, callForUint256(sut, alice, abi.encodeWithSignature("nonces(address)", alice)));

    uint256 deadline = block.timestamp + 10 minutes;

    (uint8 v, bytes32 r, bytes32 s) = getPermitSignature_(aliceKey, alice, bob, 0, deadline, 0);

    vm.expectEmit();
    emit IERC721.Approval(alice, bob, 0);

    callForVoid(
      sut,
      bob,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)", alice, bob, 0, deadline, 0, v, r, s
      )
    );

    assertEq(bob, callForAddress(sut, bob, abi.encodeWithSignature("getApproved(uint256)", 0)));
    assertEq(1, callForUint256(sut, alice, abi.encodeWithSignature("nonces(address)", alice)));
  }

  function getPermitSignature_(
    uint256 ownerKey,
    address owner,
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint256 nonce
  ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
    bytes32 h = keccak256(abi.encode(owner, spender, tokenId, deadline, nonce));

    (v, r, s) = vm.sign(ownerKey, h);
  }
}
