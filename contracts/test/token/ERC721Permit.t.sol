// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

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

  function table_permit_throws_withInvalidPermitData(SUTDatum memory sutDatum) public {
    expectCallRevert(
      IERC721Permit.InvalidPermitData.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)",
        address(0),
        address(0),
        0,
        block.timestamp + 10 minutes,
        0,
        0,
        "",
        ""
      )
    );
  }

  function table_permit_throws_withExpiredDeadline(SUTDatum memory sutDatum) public {
    address owner = alice;
    address spender = bob;
    uint256 tokenId = 0;
    uint256 deadline = block.timestamp + 10 minutes;
    uint64 nonce = 0;
    bytes32 h = keccak256(abi.encode(owner, spender, tokenId, deadline, nonce));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, h);

    skip(20 minutes);

    expectCallRevert(
      IERC721Permit.DeadlineExpired.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)",
        owner,
        spender,
        tokenId,
        deadline,
        nonce,
        v,
        r,
        s
      )
    );
  }

  function table_permit_throws_withInvalidNonce(SUTDatum memory sutDatum) public {
    address owner = alice;
    address spender = bob;
    uint256 tokenId = 0;
    uint256 deadline = block.timestamp + 10 minutes;
    uint64 nonce = 123;
    bytes32 h = keccak256(abi.encode(owner, spender, tokenId, deadline, nonce));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, h);

    expectCallRevert(
      IERC721Permit.InvalidNonce.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)",
        owner,
        spender,
        tokenId,
        deadline,
        nonce,
        v,
        r,
        s
      )
    );
  }

  function table_permit_throws_withIncorrectRecoveredAddress(SUTDatum memory sutDatum) public {
    address owner = alice;
    address spender = bob;
    uint256 tokenId = 0;
    uint256 deadline = block.timestamp + 10 minutes;
    uint64 nonce = 0;
    bytes32 h = keccak256(abi.encode(owner, spender, tokenId, deadline, nonce));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, h);

    expectCallRevert(
      IERC721Permit.InvalidSigner.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature(
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)",
        spender, // swapped owner and spender
        owner,
        tokenId,
        deadline,
        nonce,
        v,
        r,
        s
      )
    );
  }
}
