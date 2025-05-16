// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO: document
interface IOwnable2Steps {
  function owner() external view returns (address);
  function pendingOwner() external view returns (address);
  function transferOwnership(address newOwner) external;
  function acceptOwnership() external;
  function renounceOwnership() external;
}
