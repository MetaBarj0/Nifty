// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @title an interface exposing permit feature for NFT
 */
interface IERC721Permit {
  /*
   * @notice An error triggered when invalid permit data are passed to a permit
   * call
   */
  error InvalidPermitData();

  /*
   * @notice An error triggered when the permit deadline has expired
   */
  error DeadlineExpired();

  /*
   * @notice An error triggered when the recovered address does not match the
   * owner
   */
  error InvalidSigner();

  /*
   * @notice The permit function allows a sponsor to execute an approval on
   *         behalf of the owner of a token, provided the arguments are correct
   * @param owner the owner of the token to approve
   * @param spender the user to approve for a token
   * @param tokenId the token to approve for a user
   * @param deadline the period of validity for the permit
   * @param nonce the owner nonce for this permit
   * @param v signature component
   * @param r signature component
   * @param s signature component
   */
  function permit(
    address owner,
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint64 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
