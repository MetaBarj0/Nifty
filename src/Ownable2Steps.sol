// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "./interfaces/INifty.sol";
import { IOwnable2Steps } from "./interfaces/IOwnable2Steps.sol";

contract Ownable2Steps is IOwnable2Steps {
  address internal owner_;
  address internal pendingOwner_;

  constructor(address ownerAtIinitialization) {
    owner_ = ownerAtIinitialization;
  }

  function owner() external view virtual returns (address) {
    return owner_;
  }

  function pendingOwner() external view virtual returns (address) {
    return pendingOwner_;
  }

  function transferOwnership(address newOwner) external virtual {
    require(msg.sender == owner_, INifty.Unauthorized());

    pendingOwner_ = newOwner;

    emit IOwnable2Steps.OwnerChanging(newOwner);
  }

  function acceptOwnership() external virtual {
    require(msg.sender == pendingOwner_, INifty.Unauthorized());

    address oldOwner = owner_;
    owner_ = msg.sender;
    pendingOwner_ = address(0);

    emit OwnerChanged(oldOwner, msg.sender);
  }

  function renounceOwnership() external virtual {
    require(msg.sender == owner_ && address(0) == pendingOwner_, INifty.Unauthorized());

    address oldOwner = owner_;
    owner_ = address(0);

    emit OwnerChanged(oldOwner, address(0));
  }
}
