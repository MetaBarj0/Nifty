// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface to implement the on receive token, kind of wallet
///  interface
/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
  /// @notice Handle the receipt of an NFT
  /// @dev The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. Return of other than the magic value MUST result in the
  ///  transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param operator The address which called `safeTransferFrom` function
  /// @param from The address which previously owned the token
  /// @param tokenId The NFT identifier which is being transferred
  /// @param data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  ///  unless throwing
  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    external
    returns (bytes4);
}
