// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721Permit } from "../../src/interfaces/token/IERC721Permit.sol";

import { INifty } from "../../src/interfaces/INifty.sol";

import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract ERC721Tests is NiftyTestUtils {
  address private alice;

  function setUp() public {
    alice = makeAddr("Alice");
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
        "permit(address,address,uint256,uint256,uint64,uint8,bytes32,bytes32)", address(0), address(0), 0, 0, 0, "", ""
      )
    );
  }
}
