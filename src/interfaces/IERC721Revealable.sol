// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title present the interface to implement the commit reveal token URI
///  pattern
interface IERC721Revealable {
  /// @notice The facility to setup the reveal for tokens
  /// @dev Must throw if not called by owner
  ///  Must throw if baseUriHash is empty
  ///  Must throw if allTokensURIBeforeReveal is empty
  ///  Must throw if revealTimeLock is before this block timestamp
  /// @param baseURIHash the keccak256 hash of the final base URI for all
  ///   tokens
  /// @param allTokensURIBeforeReveal the URI for all tokens before the reveal
  /// @param revealTimeLock the amount of second that must pass before
  ///  considering the reveal as completed.
  function setupRevealProperties(uint256 baseURIHash, string memory allTokensURIBeforeReveal, uint256 revealTimeLock)
    external;

  /// @notice Returns the token URI before the reveal date.
  /// @dev Must throw if the token is not minted or has been burnt
  ///  Must throw if setupRevealProperties has not been successfully called beforehand
  /// @param tokenId a valid token id that is, already minted
  /// @return The URI of the token before the reveal date
  function tokenURIBeforeReveal(uint256 tokenId) external returns (string memory);
}
