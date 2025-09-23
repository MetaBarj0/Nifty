// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title An interface to implement the withdraw pattern for a NFT
interface IWithdrawable {
  /// @notice specific error thrown if the low level ether transfer fails in a
  ///  withdraw function call
  error TransferFailed();

  /// @notice specific error thrown if the withdraw operation is locked
  /// @dev withdraw is locked either if:
  ///  - reveal commitments have not been done yet
  ///  - withdraw is still time locked
  error WithdrawLocked();

  /// @notice handle withdraw of ethers hold in this contract subsequently to
  ///  token mint
  /// @dev This function MUST throw if not called by the contract owner
  ///  Must throw if called before commitRevealProperties successful call
  ///  Must throw if called before the reveal lock has expired
  function withdraw() external;
}
