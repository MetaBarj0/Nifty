// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { ERC165 } from "./ERC165.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { INifty } from "./interfaces/INifty.sol";

contract Nifty is INifty, ERC165 {
  address public immutable creator;

  mapping(uint256 => address) public tokenIdToOwner;
  mapping(address => uint256) balances;
  mapping(uint256 => address) private tokenIdToApproved;
  mapping(address owner => mapping(address operator => bool)) ownerToOperatorApproval;

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
    require(tokenIdToOwner[tokenId] == address(0), TokenAlreadyMinted());

    tokenIdToOwner[tokenId] = to;
    balances[to]++;

    emit IERC721.Transfer(address(0), to, tokenId);
  }
}
