// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721Metadata } from "../../src/interfaces/token/IERC721Metadata.sol";

import { INifty } from "../../src/interfaces/token/INifty.sol";

import { Test } from "forge-std/Test.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract ERC721MetadataTests is Test, NiftyTestUtils {
  address private alice;

  function setUp() public {
    alice = makeAddr("Alice");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_name_succeeds_afterDeploy(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    assertEq("Nifty", callForString(sut, user, abi.encodeWithSignature("name()")));
  }

  function table_symbol_succeeds_afterDeploy(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    assertEq("NFT xD", callForString(sut, user, abi.encodeWithSignature("symbol()")));
  }

  function table_tokenURI_throws_forInvalidTokenId(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    vm.expectRevert(INifty.InvalidTokenId.selector);
    callForString(sut, user, abi.encodeWithSignature("tokenURI(uint256)", 0));
  }

  function table_tokenURI_throws_forBurntToken(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    paidMintNew(sut, alice, 0);

    callForVoid(sut, alice, abi.encodeWithSignature("burn(uint256)", 0));

    vm.expectRevert(INifty.InvalidTokenId.selector);
    callForString(sut, user, abi.encodeWithSignature("tokenURI(uint256)", 0));
  }
}
