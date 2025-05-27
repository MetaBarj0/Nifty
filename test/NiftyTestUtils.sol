// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Nifty } from "../src/Nifty.sol";

abstract contract NiftyTestUtils {
  Nifty internal nifty;

  constructor() {
    nifty = new Nifty();
  }

  function paidMint(address to, uint256 tokenId) internal {
    nifty.mint{ value: 500 gwei }(to, tokenId);
  }
}
