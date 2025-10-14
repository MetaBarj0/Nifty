// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC165 } from "../../src/interfaces/introspection/IERC165.sol";

import { IERC721 } from "../../src/interfaces/token/IERC721.sol";
import { IERC721Enumerable } from "../../src/interfaces/token/IERC721Enumerable.sol";
import { IERC721Metadata } from "../../src/interfaces/token/IERC721Metadata.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

import { Test } from "forge-std/Test.sol";

contract ERC165Tests is Test, NiftyTestUtils {
  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return testGetSutDataForNifty();
  }

  function table_supports_interface(SUTDatum calldata sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    assertCallTrue(sut, user, abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC165).interfaceId));
    assertCallTrue(sut, user, abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC721).interfaceId));
    assertCallTrue(sut, user, abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC721Enumerable).interfaceId));
    assertCallTrue(sut, user, abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC721Metadata).interfaceId));
  }
}
