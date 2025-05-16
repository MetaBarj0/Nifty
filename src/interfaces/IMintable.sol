// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintable {
  /// @notice A specific IMintable error
  /// @dev specifically thrown when mint function is called with a wrong
  ///  amount of wei
  error WrongPaymentValue();

  /// @notice A payable mint feature
  /// @dev Using this function a user can mint a token for a fee. You can
  ///  disable it in implementation by throwing if you like.
  ///  According to IERC721, a mint must emit the Transfer event with the
  ///  `from` parameter set to address(0)
  /// @param to the user to mint token for. Cannot be 0 address.
  /// @param tokenId the identifier of the token to mint. A token with this
  ///  identifier must not already exist.
  function mint(address to, uint256 tokenId) external payable;
}
