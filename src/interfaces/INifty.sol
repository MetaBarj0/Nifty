// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165 } from "./introspection/IERC165.sol";
import { IERC721 } from "./token/IERC721.sol";
import { IERC721Enumerable } from "./token/IERC721Enumerable.sol";
import { IERC721Metadata } from "./token/IERC721Metadata.sol";
import { IERC721TokenReceiver } from "./token/IERC721TokenReceiver.sol";

import { IOwnable2Steps } from "./IOwnable2Steps.sol";
import { IPausable } from "./IPausable.sol";
import { IRevealable } from "./IRevealable.sol";
import { IWithdrawable } from "./IWithdrawable.sol";

import { IInitializable } from "./proxy/IInitializable.sol";
import { IBurnable } from "./token/IBurnable.sol";
import { IMintable } from "./token/IMintable.sol";

/// @title The minimal set of features to implement a INifty like token
interface INifty is
  IInitializable,
  IERC721,
  IERC721Enumerable,
  IERC721Metadata,
  IOwnable2Steps,
  IMintable,
  IBurnable,
  IWithdrawable,
  IRevealable,
  IPausable
{
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
  error InvalidReceiver();
}
