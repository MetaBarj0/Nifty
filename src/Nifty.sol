// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { ERC165 } from "./ERC165.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IERC721Enumerable } from "./interfaces/IERC721Enumerable.sol";
import { IERC721TokenReceiver } from "./interfaces/IERC721TokenReceiver.sol";
import { INifty } from "./interfaces/INifty.sol";

contract Nifty is INifty, IERC721Enumerable, ERC165 {
  address public immutable creator;

  mapping(uint256 => address) private tokenIdToOwner;
  mapping(address => uint256) private balances;
  mapping(uint256 => address) private tokenIdToApproved;
  mapping(address owner => mapping(address operator => bool)) private ownerToOperatorApproval;
  mapping(uint256 tokenId => uint256 tokensIndex) private tokenIdToAllTokensIndex;
  mapping(address owner => mapping(uint256 index => uint256 tokenId)) private ownerTokenIndexToTokenId;
  mapping(address owner => mapping(uint256 tokenId => uint256 tokenIndex)) private ownerTokenIdToTokenIndex;

  uint256[] private allTokens;

  constructor() {
    creator = msg.sender;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
    return interfaceId == type(INifty).interfaceId || super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner) external view returns (uint256) {
    return balances[owner];
  }

  function ownerOf(uint256 tokenId) external view returns (address) {
    address owner = tokenIdToOwner[tokenId];

    require(owner != address(0), INifty.InvalidTokenId());

    return owner;
  }

  function transferFrom(address, address, uint256) external payable {
    revert Unsupported();
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable {
    address tokenOwner = tokenIdToOwner[tokenId];
    address approved = tokenIdToApproved[tokenId];
    bool isOperator = ownerToOperatorApproval[tokenOwner][msg.sender];

    require(msg.sender == tokenOwner || msg.sender == approved || isOperator, Unauthorized());

    balances[from]--;
    balances[to]++;
    tokenIdToOwner[tokenId] = to;
    delete tokenIdToApproved[tokenId];

    tryReceive(msg.sender, from, to, tokenId, data);

    emit IERC721.Transfer(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
    safeTransferFrom(from, to, tokenId, "");
  }

  function approve(address approved, uint256 tokenId) external payable {
    address tokenOwner = tokenIdToOwner[tokenId];

    require(msg.sender == tokenIdToOwner[tokenId] || ownerToOperatorApproval[tokenOwner][msg.sender], Unauthorized());

    tokenIdToApproved[tokenId] = approved;
    emit IERC721.Approval(tokenOwner, approved, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external {
    ownerToOperatorApproval[msg.sender][operator] = approved;

    emit IERC721.ApprovalForAll(msg.sender, operator, approved);
  }

  function getApproved(uint256 tokenId) external view returns (address) {
    address owner = tokenIdToOwner[tokenId];
    require(owner != address(0), InvalidTokenId());

    return tokenIdToApproved[tokenId];
  }

  function isApprovedForAll(address owner, address operator) external view returns (bool) {
    return ownerToOperatorApproval[owner][operator];
  }

  function mint(address to, uint256 tokenId) external {
    require(to != address(0), InvalidAddress());
    require(tokenIdToOwner[tokenId] == address(0), TokenAlreadyMinted());

    tokenIdToOwner[tokenId] = to;

    allTokens.push(tokenId);
    tokenIdToAllTokensIndex[tokenId] = allTokens.length - 1;

    ownerTokenIndexToTokenId[to][balances[to]] = tokenId;
    ownerTokenIdToTokenIndex[to][tokenId] = balances[to];

    balances[to]++;

    tryReceive(msg.sender, address(0), to, tokenId, "");

    emit IERC721.Transfer(address(0), to, tokenId);
  }

  function burn(uint256 tokenId) external {
    address tokenOwner = tokenIdToOwner[tokenId];
    require(tokenOwner != address(0), InvalidTokenId());
    require(
      tokenOwner == msg.sender || tokenIdToApproved[tokenId] == msg.sender
        || ownerToOperatorApproval[tokenOwner][msg.sender],
      Unauthorized()
    );

    uint256 tokenIndex = tokenIdToAllTokensIndex[tokenId];
    uint256 lastTokenIndex = allTokens.length - 1;
    uint256 lastTokenId = allTokens[lastTokenIndex];
    allTokens[tokenIndex] = lastTokenId;
    allTokens.pop();
    delete tokenIdToAllTokensIndex[tokenId];
    tokenIdToAllTokensIndex[lastTokenId] = tokenIndex;

    uint256 ownerTokenIndex = ownerTokenIdToTokenIndex[tokenOwner][tokenId];
    uint256 lastOwnerTokenIndex = balances[tokenOwner] - 1;
    uint256 lastOwnerTokenId = ownerTokenIndexToTokenId[tokenOwner][lastOwnerTokenIndex];
    ownerTokenIndexToTokenId[tokenOwner][ownerTokenIndex] = lastOwnerTokenId;
    delete ownerTokenIndexToTokenId[tokenOwner][lastOwnerTokenIndex];
    ownerTokenIdToTokenIndex[tokenOwner][lastOwnerTokenId] = ownerTokenIndex;

    delete tokenIdToOwner[tokenId];
    balances[tokenOwner]--;
  }

  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  function tokenByIndex(uint256 index) external view returns (uint256) {
    require(index < totalSupply(), IndexOutOfBound());

    return allTokens[index];
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    require(owner != address(0), InvalidTokenId());
    require(index < balances[owner], IndexOutOfBound());

    return ownerTokenIndexToTokenId[owner][index];
  }

  function tryReceive(address operator, address from, address to, uint256 tokenId, bytes memory data) private {
    if (to.code.length > 0) {
      try IERC721TokenReceiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 result) {
        require(result == IERC721TokenReceiver.onERC721Received.selector, InvalidReceiver(to));
      } catch (bytes memory reason) {
        if (reason.length > 0) {
          assembly ("memory-safe") {
            revert(add(reason, 0x20), mload(reason))
          }
        } else {
          revert InvalidReceiver(to);
        }
      }
    }
  }
}
