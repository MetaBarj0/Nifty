// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC165 } from "../src/interfaces/introspection/IERC165.sol";
import { IERC721 } from "../src/interfaces/token/IERC721.sol";
import { IERC721TokenReceiver } from "../src/interfaces/token/IERC721TokenReceiver.sol";

import { ERC165 } from "../src/introspection/ERC165.sol";

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

contract TriviallyConstructibleContract { }

contract FailingInitializableImplementation {
  function initialize() external pure {
    revert();
  }
}

contract TestImplementation {
  uint256 public foo;

  function initialize(uint256 value) public virtual {
    foo = value;
  }

  function admin() external pure returns (address) {
    return address(42);
  }

  function implementation() external pure returns (address) {
    return address(43);
  }

  function inc() external {
    inc_();
  }

  function inc_() internal virtual {
    foo++;
  }
}

contract TestNewImplementation is TestImplementation {
  uint256 public bar;

  function initialize(uint256 baseValue, uint256 newValue) external {
    super.initialize(baseValue);
    bar = newValue;
  }

  function inc_() internal override {
    super.inc_();
    bar++;
  }
}

contract NonCompliantReceiver is IERC721TokenReceiver {
  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
    return bytes4(uint32(42));
  }
}

contract NonPayableContract {
  string private constant S = "Can't accept this, this is too much";

  receive() external payable {
    revert(S);
  }
}

contract NotERC165 { }

contract NotERC165Too is ERC165 {
  function supportsInterface(bytes4) public pure override returns (bool) {
    return false;
  }
}

contract NotERC721 is ERC165 { }

contract NotMintable is IERC721, ERC165 {
  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC165) returns (bool) {
    return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
  }

  // NOTE: test file, I don't care to test unused function below
  function test() external pure { }

  function balanceOf(address owner) external view returns (uint256) { }
  function ownerOf(uint256 tokenId) external view returns (address) { }
  function transferFrom(address from, address to, uint256 tokenId) external payable { }
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable { }
  function safeTransferFrom(address from, address to, uint256 tokenId) external payable { }
  function approve(address approved, uint256 tokenId) external payable { }
  function setApprovalForAll(address operator, bool approved) external { }
  function getApproved(uint256 tokenId) external view returns (address) { }
  function isApprovedForAll(address owner, address operator) external view returns (bool) { }
}
