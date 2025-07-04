// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title An interface to implement the withdraw pattern for a NFT
interface IERC721Withdrawable {
  /// @notice specific error thrown if the low level ether transfer fails in a
  ///  withdraw function call
  error TransferFailed();

  /// @notice handle withdraw of ethers hold in this contract subsequently to
  ///  token mint
  /// @dev This function MUST throw if not called by the contract owner
  function withdraw() external;
}
