// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title present the interface to implement the commit reveal token URI
///  pattern
interface IPausable {
  /// @notice A specific error regarding the pausable feature of this NFT
  /// @dev The pause can affect both minting and burning
  error MintAndBurnPaused();

  /// @notice Pauses both the minting and burning features of this NFT
  /// @dev MUST throw if not called by owner
  function pause() external;

  /// @notice Resumes both the minting and burning features of this NFT
  /// @dev MUST throw if not called by owner
  function resume() external;

  /// @notice Indicates if the minting and burning features are paused
  function paused() external view returns (bool);

  /// @notice emmitted after a successful pause call
  event Paused();

  /// @notice emmitted after a successful resume call
  event Resumed();
}
