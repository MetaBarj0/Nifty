// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title An interface for NFT burning feature
interface IERC721Burnable {
  /// @notice A specific burn feature
  /// @dev Using this function a token owner can burn his owned previously
  ///  minted tokens. You can disable it in implementation by throwing if you
  ///  like. You may not refund the user when he burns his tokens if you wish.
  /// @param tokenId the identifier of a token to burn. The token must be owned
  ///  by the user.
  function burn(uint256 tokenId) external;
}
