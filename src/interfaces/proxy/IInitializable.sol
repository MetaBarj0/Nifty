// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @notice Define a way to initialize a contract after its deployment
 * @dev The only way to initialize a transparent proxy state when the proxy is
 *      deployed.
 */
interface IInitializable {
  /*
   * @notice initialize the implementation contract after its deployment
   * @dev delegatecall this function within the proxy constructor to ensure the
   *      proxy state is initialized as the implementation contract is.
   */
  function initialize(bytes calldata data) external;
}
