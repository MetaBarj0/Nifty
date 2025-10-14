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

  /// @notice Emitted when the underlying contract implementation has changed
  event ImplementationChanged(address oldImplementation);

  /// @notice accessor for the admin address of the proxy deployment
  /// @dev Only executed if called by the actual admin. If sender is not the
  ///  admin, the call must be forwarded to the actual implementation
  /// @return The admin address of the proxy
  // TODO: might be view
  function admin() external returns (address);

  /// @notice accessor for the implementation logic contract address
  /// @dev Only executed if called by the actual admin. If sender is not the
  ///  admin, the call must be forwarded to the actual implementation
  /// @return The address of the logic contract
  // TODO: might be view
  function implementation() external returns (address);

  /// @notice upgrade the underlying implementation of this proxy instance and
  ///  make a call to initialize it if necessary.
  /// @dev MUST throw if not called by admin
  ///  MUST throw if newImplementation is invalid that is:
  ///  - zero address
  ///  - not a deployed contract
  ///  - cannot match a function call with encodedCall argument
  ///  MUST emit an ImplementationChanged event on success
  /// @param newImplementation the address of the contract to handle. It is the
  ///  responsibility of the deployer the new contract is as compatible with the
  ///  old one as much as possible to avoid state collision.
  /// @param encodedCall an encoded call to an initialization function
  function upgradeToAndCall(address newImplementation, bytes calldata encodedCall) external;
}
