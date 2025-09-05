// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721TokenReceiver } from "../src/interfaces/IERC721TokenReceiver.sol";

contract NonCompliantReceiver is IERC721TokenReceiver {
  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
    return bytes4(uint32(42));
  }
}
