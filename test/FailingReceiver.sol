// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { IERC721TokenReceiver } from "../src/interfaces/IERC721TokenReceiver.sol";

contract FailingReceiver is IERC721TokenReceiver {
  error OhShit();

  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
    revert OhShit();
  }
}
