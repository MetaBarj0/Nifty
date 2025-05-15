// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721 } from "./IERC721.sol";

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

  /// @notice A specific INifty mint feature
  /// @dev Using this function a user can mint a token for free. You can
  ///  disable it in implementation by throwing if you like.
  ///  According to IERC721, a mint must emit the Transfer event with the
  ///  `from` parameter set to address(0)
  /// @param to the user to mint token for. Cannot be 0 address.
  /// @param tokenId the identifier of the token to mint. A token with this
  ///  identifier must not already exist.
  function mint(address to, uint256 tokenId) external;

  /// @notice A specific INifty burn feature
  /// @dev Using this function a token owner can burn his owned previously
  ///  minted tokens. You can disable it in implementation by throwing if you
  ///  like.
  ///  According to IERC721, a mint must emit the Transfer event with the
  ///  `from` parameter set to address(0)
  /// @param tokenId the identifier of a token to burn. The token must be owned
  ///  by the user.
  function burn(uint256 tokenId) external;
}
