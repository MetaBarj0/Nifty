// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC165 } from "../src/ERC165.sol";
import { IInitializable } from "../src/interfaces/IInitializable.sol";

contract FailingInitializableImplementation is ERC165, IInitializable {
  function initialize(bytes calldata) external pure override {
    revert();
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == type(IInitializable).interfaceId || super.supportsInterface(interfaceId);
  }
}
