// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Ownable2Steps {
  /// @notice Get the current owner of the contract implementation
  /// @dev Single owner, may be changed in 2 steps.
  function owner() external view returns (address);

  /// @notice Get the pending owner. The pending owner must accept the
  ///  ownership change by calling acceptOwnership
  /// @dev Single owner, may be changed in 2 steps.
  function pendingOwner() external view returns (address);

  /// @notice start the process of changing the actual owner or reset the
  ///  process of changing the actual owner
  /// @dev Throws if sender is not the actual owner. The new owner has to
  ///  accept the ownership before owner change to be effective.
  /// @param newOwner the new owner the actual owner wants to transfer the
  ///  ownership to. If set with address(0), no change in ownership is asked
  ///  anymore.
  function transferOwnership(address newOwner) external;

  /// @notice finish the process of changing the actual owner.
  /// @dev Throws unless sender is the pending owner specified by a
  ///  transferOwnership call.
  function acceptOwnership() external;

  /// @notice renounce to the ownership.
  /// @dev After this call, no one owns the contract anymore and nobody can own
  ///  this contract anymore in the future.
  function renounceOwnership() external;
}
