// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721 } from "./IERC721.sol";

// TODO: spread errors in related interfaces when applicable
interface INifty is IERC721 {
  /// @notice A specify INifty error
  /// @dev Specifically thrown at mint time if the provided token id has
  ///  already be minted in case if its' not self-explanatory enough
  error TokenAlreadyMinted();

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
  /// @dev Specifically thrown when using an invalid address (e.g. 0 address at
  ///  minting) with INifty functions.
  error InvalidAddress();

  /// @notice A specific INifty error
  /// @dev Specifically thrown when using ERC721 enumerable features
  error IndexOutOfBound();

  /// @notice A specific INifty error
  /// @dev specifically thrown in a safeTransferFrom call that fail to call a
  ///  compliant onERC721Received function as defined in the
  ///  IERC721TokenReceiver interface
  /// @param to the faulty receiver address
  error InvalidReceiver(address to);
}
