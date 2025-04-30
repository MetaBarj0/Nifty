// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { ERC165 } from "./ERC165.sol";
import { INifty } from "./interfaces/INifty.sol";

contract Nifty is INifty, ERC165 {
  address public immutable creator;

  constructor() {
    creator = msg.sender;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(INifty).interfaceId || super.supportsInterface(interfaceId);
  }
}
