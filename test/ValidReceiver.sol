// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721TokenReceiver } from "../src/interfaces/IERC721TokenReceiver.sol";

contract ValidReceiver is IERC721TokenReceiver {
  event Received(address indexed operator, address indexed from, uint256 indexed tokenId);

  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory)
    external
    override
    returns (bytes4)
  {
    emit Received(operator, from, tokenId);

    return IERC721TokenReceiver.onERC721Received.selector;
  }
}
