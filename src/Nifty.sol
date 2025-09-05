// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/utils/Strings.sol";

import { IERC165 } from "./interfaces/IERC165.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IERC721Burnable } from "./interfaces/IERC721Burnable.sol";
import { IERC721Enumerable } from "./interfaces/IERC721Enumerable.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import { IERC721Mintable } from "./interfaces/IERC721Mintable.sol";
import { IERC721Ownable2Steps } from "./interfaces/IERC721Ownable2Steps.sol";
import { IERC721Pausable } from "./interfaces/IERC721Pausable.sol";
import { IERC721Revealable } from "./interfaces/IERC721Revealable.sol";
import { IERC721TokenReceiver } from "./interfaces/IERC721TokenReceiver.sol";
import { IERC721Withdrawable } from "./interfaces/IERC721Withdrawable.sol";
import { INifty } from "./interfaces/INifty.sol";

import { ERC165 } from "./ERC165.sol";

// TODO: @inheritdoc for all
contract Nifty is
  INifty,
  IERC721,
  IERC721Enumerable,
  IERC721Metadata,
  IERC721Ownable2Steps,
  IERC721Mintable,
  IERC721Burnable,
  IERC721Withdrawable,
  IERC721Revealable,
  IERC721Pausable,
  ERC165
{
  address public immutable creator;

  mapping(uint256 => address) private tokenIdToOwner;
  mapping(address => uint256) private balances;
  mapping(uint256 => address) private tokenIdToApproved;
  mapping(address owner => mapping(address operator => bool)) private ownerToOperatorApproval;
  mapping(uint256 tokenId => uint256 tokensIndex) private tokenIdToAllTokensIndex;
  mapping(address owner => mapping(uint256 index => uint256 tokenId)) private ownerTokenIndexToTokenId;
  mapping(address owner => mapping(uint256 tokenId => uint256 tokenIndex)) private ownerTokenIdToTokenIndex;

  uint256[] private allTokens;

  address private owner_;
  address private pendingOwner_;

  string baseURI_;
  uint256 baseURICommitment_;
  uint256 revealTimeLockEnd_;
  uint256 withdrawTimeLockEnd_;

  bool paused_;

  constructor() {
    creator = msg.sender;
    owner_ = msg.sender;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
    return interfaceId == type(INifty).interfaceId || super.supportsInterface(interfaceId);
  }

  function balanceOf(address tokenOwner) external view returns (uint256) {
    return balances[tokenOwner];
  }

  function ownerOf(uint256 tokenId) external view returns (address) {
    address tokenOwner = tokenIdToOwner[tokenId];

    require(tokenOwner != address(0), INifty.InvalidTokenId());

    return tokenOwner;
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
    address tokenOwner = tokenIdToOwner[tokenId];
    require(tokenOwner != address(0), InvalidTokenId());

    return tokenIdToApproved[tokenId];
  }

  function isApprovedForAll(address tokenOwner, address operator) external view returns (bool) {
    return ownerToOperatorApproval[tokenOwner][operator];
  }

  function mint(address to, uint256 tokenId) external payable {
    require(!paused_, MintAndBurnPaused());
    require(to != address(0), InvalidAddress());
    require(tokenIdToOwner[tokenId] == address(0), TokenAlreadyMinted());
    require(msg.value == 500 gwei, WrongPaymentValue());

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
    require(!paused_, MintAndBurnPaused());
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

    emit IERC721.Transfer(msg.sender, address(0), tokenId);
  }

  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  function tokenByIndex(uint256 index) external view returns (uint256) {
    require(index < totalSupply(), IndexOutOfBound());

    return allTokens[index];
  }

  function tokenOfOwnerByIndex(address tokenOwner, uint256 index) external view returns (uint256) {
    require(tokenOwner != address(0), InvalidTokenId());
    require(index < balances[tokenOwner], IndexOutOfBound());

    return ownerTokenIndexToTokenId[tokenOwner][index];
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

  function name() external pure override returns (string memory) {
    return "Nifty";
  }

  function symbol() external pure override returns (string memory) {
    return "NFT xD";
  }

  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    address tokenOwner = tokenIdToOwner[tokenId];

    require(tokenOwner != address(0), INifty.InvalidTokenId());

    return baseURICommitment_ != 0 || (baseURICommitment_ == 0 && bytes(baseURI_).length == 0)
      ? baseURI_
      : string.concat(baseURI_, "/", Strings.toString(tokenId), ".svg");
  }

  function owner() external view returns (address) {
    return owner_;
  }

  function pendingOwner() external view returns (address) {
    return pendingOwner_;
  }

  function transferOwnership(address newOwner) external {
    require(owner_ == msg.sender, Unauthorized());

    pendingOwner_ = newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner_, Unauthorized());

    owner_ = pendingOwner_;
    pendingOwner_ = address(0);
  }

  function renounceOwnership() external override {
    require(msg.sender == owner_ && address(0) == pendingOwner_, Unauthorized());

    owner_ = address(0);
  }

  function withdraw() external {
    require(msg.sender == owner_, Unauthorized());
    require(
      bytes(baseURI_).length != 0 && baseURICommitment_ == 0 && block.timestamp >= withdrawTimeLockEnd_,
      IERC721Withdrawable.WithdrawLocked()
    );

    (bool success,) = payable(owner_).call{ value: address(this).balance }("");

    require(success, IERC721Withdrawable.TransferFailed());
  }

  function commitRevealProperties(
    uint256 baseURICommitment,
    string calldata allTokensURIBeforeReveal,
    uint256 revealTimeLock,
    uint256 withdrawTimeLockAferReveal
  ) external {
    require(msg.sender == owner_, INifty.Unauthorized());
    require(
      baseURICommitment != 0 && bytes(allTokensURIBeforeReveal).length != 0 && revealTimeLock > 0
        && withdrawTimeLockAferReveal > 0,
      IERC721Revealable.InvalidRevealProperties()
    );

    baseURI_ = allTokensURIBeforeReveal;
    baseURICommitment_ = baseURICommitment;
    revealTimeLockEnd_ = block.timestamp + revealTimeLock;
    withdrawTimeLockEnd_ = block.timestamp + revealTimeLock + withdrawTimeLockAferReveal;
  }

  function revealTimeLockEnd() external view returns (uint256) {
    return revealTimeLockEnd_;
  }

  function reveal(string calldata baseURI) external {
    require(msg.sender == owner_, INifty.Unauthorized());
    require(baseURICommitment_ == uint256(keccak256(abi.encodePacked(baseURI))), IERC721Revealable.WrongPreimage());

    baseURICommitment_ = 0;
    baseURI_ = baseURI;
  }

  function pause() external {
    require(msg.sender == owner_, INifty.Unauthorized());

    paused_ = true;
  }

  function resume() external {
    require(msg.sender == owner_, INifty.Unauthorized());

    paused_ = false;
  }

  function paused() external view returns (bool) {
    return paused_;
  }

  function withdrawTimeLockEnd() external view returns (uint256) {
    return withdrawTimeLockEnd_;
  }
}
