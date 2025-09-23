// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721TokenReceiver } from "../src/interfaces/IERC721TokenReceiver.sol";
import { IInitializable } from "../src/interfaces/IInitializable.sol";

import { ERC165 } from "../src/ERC165.sol";

contract FailingReceiver is IERC721TokenReceiver {
  error OhShit();

  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
    revert OhShit();
  }
}

contract InvalidReceiver { }

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

contract FailingInitializableImplementation is ERC165, IInitializable {
  function initialize(bytes calldata) external pure override {
    revert();
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == type(IInitializable).interfaceId || super.supportsInterface(interfaceId);
  }
}

contract TestImplementation is ERC165, IInitializable {
  uint256 public foo;

  function initialize(bytes calldata data) external override {
    (uint256 value) = abi.decode(data, (uint256));
    foo = value;
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == type(IInitializable).interfaceId || super.supportsInterface(interfaceId);
  }

  function admin() external pure returns (string memory) {
    return "admin from implementation";
  }

  function implementation() external pure returns (string memory) {
    return "implementation from implementation";
  }

  function inc() external {
    foo++;
  }
}

contract NotInitializableImplementation { }

contract NonCompliantReceiver is IERC721TokenReceiver {
  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
    return bytes4(uint32(42));
  }
}
