// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title The minimal set of features to implement a INifty like token
interface INifty {
  /// @notice A specific INifty error
  /// @dev Specifically thrown at ownership check
  error InvalidTokenId();

  /// @notice A specific INifty error
  /// @dev Specifically thrown when attempted operation are forbidden because
  ///  of ownership or approval issues.
  error Unauthorized();

  /// @notice A specific INifty error
  /// @dev Specifically thrown when calling unsupported operation in
  ///  implementation contract (for instance, Nifty.transferFrom)
  error Unsupported();

  /// @notice A specific INifty error
  /// @dev Specifically thrown when transfering to 0 address
  error ZeroAddress();

  /// @notice A specific INifty error
  /// @dev specifically thrown in a safeTransferFrom call that fail to call a
  ///  compliant onERC721Received function as defined in the
  ///  IERC721TokenReceiver interface
  /// @param to the faulty receiver address
  error InvalidReceiver(address to);
}
