// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Test } from "forge-std/Test.sol";

import { Nifty } from "../src/Nifty.sol";

abstract contract NiftyTestUtils is Test {
  Nifty internal nifty;

  function paidMint(address to, uint256 tokenId) internal {
    vm.deal(to, 500 gwei);

    // the to account pays for his token
    vm.startPrank(to);
    nifty.mint{ value: 500 gwei }(to, tokenId);
    vm.stopPrank();
  }
}
