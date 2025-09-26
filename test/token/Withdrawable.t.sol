// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IWithdrawable } from "../../src/interfaces/IWithdrawable.sol";
import { INifty } from "../../src/interfaces/token/INifty.sol";

import { Test } from "forge-std/Test.sol";

import { InvalidReceiver } from "../Mocks.sol";
import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract WithdrawableTests is Test, NiftyTestUtils {
  address private alice;
  address private bob;

  function setUp() public {
    alice = makeAddr("Alice");
    bob = makeAddr("Bob");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutData();
  }

  function table_withdraw_throws_ifNotCalledByOwner(SUTDatum memory sutDatum) public {
    vm.expectRevert(INifty.Unauthorized.selector);
    callForVoid(sutDatum.sut, alice, abi.encodeWithSignature("withdraw()"));
  }

  function table_withdraw_throws_ifPaymentFails(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;
    address invalidReceiver = address(new InvalidReceiver());

    paidMintNew(sut, alice, 0);
    callForVoid(
      sut,
      niftyDeployer,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256,uint256)",
        uint256(keccak256("revealed/uri")),
        "unrevealed/uri",
        1 days,
        1 days
      )
    );
    skip(1 days);
    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("reveal(string)", "revealed/uri"));
    skip(1 days);

    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("transferOwnership(address)", invalidReceiver));
    callForVoid(sut, invalidReceiver, abi.encodeWithSignature("acceptOwnership()"));

    expectCallRevert(IWithdrawable.TransferFailed.selector, sut, invalidReceiver, abi.encodeWithSignature("withdraw()"));
  }

  function table_withdraw_throws_ifCommitRevealPropertiesHasNotBeenDone(SUTDatum memory sutDatum) public {
    expectCallRevert(
      IWithdrawable.WithdrawLocked.selector, sutDatum.sut, niftyDeployer, abi.encodeWithSignature("withdraw()")
    );
  }

  function table_withdraw_throws_ifRevealedIsNotDone(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    callForVoid(
      sut,
      niftyDeployer,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256,uint256)", 1234, "unrevealed/uri", 1 days, 1 days
      )
    );

    expectCallRevert(IWithdrawable.WithdrawLocked.selector, sut, niftyDeployer, abi.encodeWithSignature("withdraw()"));
  }

  function table_withdraw_throws_ifRevealedButWithdrawIsStillLocked(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    callForVoid(
      sut,
      niftyDeployer,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256,uint256)",
        uint256(keccak256("revealed/uri")),
        "unrevealed/uri",
        1 days,
        2 days
      )
    );
    skip(1 days);
    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("reveal(string)", "revealed/uri"));

    expectCallRevert(IWithdrawable.WithdrawLocked.selector, sut, niftyDeployer, abi.encodeWithSignature("withdraw()"));
  }

  function table_withdraw_throws_ifWithdrawTimelockEndedButRevealIsNotDone(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    callForVoid(
      sut,
      niftyDeployer,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256,uint256)",
        uint256(keccak256("revealed/uri")),
        "unrevealed/uri",
        1 days,
        2 days
      )
    );
    skip(1 days);
    skip(2 days);

    expectCallRevert(IWithdrawable.WithdrawLocked.selector, sut, niftyDeployer, abi.encodeWithSignature("withdraw()"));
  }

  function table_withdraw_succeeds_ifCalledByOwnerAndWithdrawIsUnlocked(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    uint256 revenuesInContractBeforeMint = sut.balance;

    paidMintNew(sut, alice, 0);
    paidMintNew(sut, alice, 1);
    paidMintNew(sut, alice, 2);

    uint256 revenuesInContractAfterMint = sut.balance;

    callForVoid(
      sut,
      niftyDeployer,
      abi.encodeWithSignature(
        "commitRevealProperties(uint256,string,uint256,uint256)",
        uint256(keccak256("revealed/uri")),
        "unrevealed/uri",
        1 days,
        2 days
      )
    );
    skip(1 days);
    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("reveal(string)", "revealed/uri"));
    skip(2 days);

    vm.expectEmit();
    emit IWithdrawable.Withdrawn(niftyDeployer, revenuesInContractAfterMint);
    callForVoid(sut, niftyDeployer, abi.encodeWithSignature("withdraw()"));

    assertEq(revenuesInContractBeforeMint, 0);
    assertGt(revenuesInContractAfterMint, 0);
    assertEq(niftyDeployer.balance, revenuesInContractAfterMint);
    assertEq(sut.balance, 0);
  }
}
