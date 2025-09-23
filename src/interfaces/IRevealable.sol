// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title present the interface to implement the commit reveal token URI
///  pattern
interface IRevealable {
  /// @notice A specific error regarding reveal properties
  /// @dev see the setupRevealProperties function for more details
  error InvalidRevealProperties();

  /// @notice A specific error regarding reveal
  /// @dev Thrown if the specified base URI in reveal call is incorrect
  error WrongPreimage();

  /// @notice The facility to setup the reveal for tokens
  /// @dev Must throw if not called by owner
  ///  Must throw if baseUriHash argument is default value
  ///  Must throw if allTokensURIBeforeReveal argument is empty
  ///  Must throw if revealTimeLock is 0
  ///  Must throw if withdrawTimeLock is 0
  /// @param baseURICommitment the keccak256 hash of the final base URI for all
  ///   tokens
  /// @param allTokensURIBeforeReveal the URI for all tokens before the reveal
  /// @param revealTimeLock the amount of second that must pass before
  ///  considering the reveal as completed.
  /// @param withdrawTimeLockAfterReveal the amount of second that must pass
  ///  after the reveal before /  the owner is allowed to withdraw funds from
  ///  the contract
  function commitRevealProperties(
    uint256 baseURICommitment,
    string calldata allTokensURIBeforeReveal,
    uint256 revealTimeLock,
    uint256 withdrawTimeLockAfterReveal
  ) external;

  /// @notice Get the end of the reveal time lock
  /// @dev Returns 0 if not set with a prior commitRevealProperties call
  /// @return the time when all token URI can be revealed
  function revealTimeLockEnd() external view returns (uint256);

  /// @notice reveal the final base URI for all tokens of this NFT if all
  ///  conditions are met.
  /// @dev Must throw if not called by owner
  ///  Must throw if the baseURI is incorrect (wrong preimage)
  ///  An ahead of time reveal is permitted.
  /// @param baseURI the final base URI for all tokens handled by this NFT.
  function reveal(string calldata baseURI) external;

  /// @notice Get the end of the withdraw time lock
  /// @dev Returns 0 if not set with a prior commitRevealProperties call
  /// @return the time when the owner is allowed to withdraw funds from the contract
  function withdrawTimeLockEnd() external view returns (uint256);
}
