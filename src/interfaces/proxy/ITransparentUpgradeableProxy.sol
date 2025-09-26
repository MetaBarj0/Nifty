// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title An interface describing must have feature for a transparent
///  upgradeable proxy
/// @notice Contains function definition as well as custom errors
interface ITransparentUpgradeableProxy {
  /// @notice Error indicating an invalid implementation is specified in a
  ///  function argument list
  error InvalidImplementation();

  /// @notice Error thrown when the proxy admin attempts to forward a call to
  ///  the implementation
  error InvalidAdminCall();

  /// @notice Error thrown when someone attempt to send ether to this proxy
  ///  without calldata
  error ReceiveUnsupported();

  /// @notice emitted when the proxy has initialized the underlying
  ///  implementation contract.
  event ImplementationInitialized();

  /// @notice accessor for the admin address of the proxy deployment
  /// @dev Only executed if called by the actual admin. If sender is not the
  ///  admin, the call must be forwarded to the actual implementation
  /// @return The admin address of the proxy
  function admin() external returns (address);

  /// @notice accessor for the implementation logic contract address
  /// @dev Only executed if called by the actual admin. If sender is not the
  ///  admin, the call must be forwarded to the actual implementation
  /// @return The address of the logic contract
  function implementation() external returns (address);
}
