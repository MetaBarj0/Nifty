// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ICrowdsaleable } from "../src/interfaces/ICrowdsaleable.sol";
import { INifty } from "../src/interfaces/INifty.sol";

import { IERC165 } from "../src/interfaces/introspection/IERC165.sol";
import { IInitializable } from "../src/interfaces/proxy/IInitializable.sol";
import { IERC721 } from "../src/interfaces/token/IERC721.sol";
import { IERC721TokenReceiver } from "../src/interfaces/token/IERC721TokenReceiver.sol";

import { FailingReceiver, NonPayableContract } from "./Mocks.sol";
import { NiftyTestUtils, SUTDatum } from "./NiftyTestUtils.sol";

import { Test } from "forge-std/Test.sol";

contract CrowdsaleTests is Test, NiftyTestUtils {
  address private alice;

  function setUp() public {
    alice = makeAddr("alice");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutDataForCrowdsale();
  }

  function table_introspection_supportsAllRequiredInterfaces(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);
    bytes4 expectedRet = IERC721TokenReceiver.onERC721Received.selector;

    bytes4 ret = callForBytes4(
      sut,
      user,
      abi.encodeWithSignature("onERC721Received(address,address,uint256,bytes)", address(0), address(0), 0, "")
    );

    assertEq(expectedRet, ret);
    assertCallTrue(
      sut, user, abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC721TokenReceiver).interfaceId)
    );
    assertCallTrue(sut, user, abi.encodeWithSignature("supportsInterface(bytes4)", type(IInitializable).interfaceId));
    assertCallTrue(sut, user, abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC165).interfaceId));
  }

  function table_setupCrowdsale_throws_ifNotCalledByOwner(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    expectCallRevert(
      INifty.Unauthorized.selector,
      sut,
      alice,
      abi.encodeWithSignature("setupCrowdsale(uint256,uint256,uint256,uint256,uint256)", 0, 0, 0, 0, 0)
    );
  }

  function table_setupCrowdsale_throws_withOwnerCallingWithWrongSaleDates(SUTDatum memory sutDatum) public {
    uint256 now_ = block.timestamp;

    expectSetupCrowdsaleRevertWithWrongSaleDates(sutDatum.sut, 0, 0);
    expectSetupCrowdsaleRevertWithWrongSaleDates(sutDatum.sut, now_, now_);
    expectSetupCrowdsaleRevertWithWrongSaleDates(sutDatum.sut, now_ + 2 days, now_ + 1 days);
  }

  function table_setupCrowdsale_throws_withOwnerCallingWithWrongRate(SUTDatum memory sutDatum) public {
    expectSetupCrowdsaleRevertWithWrongRate(sutDatum.sut, 0);
  }

  function table_setupCrowdsale_throws_withOwnerCallingWithWrongWithdrawDates(SUTDatum memory sutDatum) public {
    uint256 now_ = block.timestamp;

    expectSetupCrowdsaleRevertWithWrongWithdrawDates(sutDatum.sut, now_ + 1 days, now_ + 2 days, 0, 0);
    expectSetupCrowdsaleRevertWithWrongWithdrawDates(sutDatum.sut, now_ + 1 days, now_ + 2 days, 1, 2);
    expectSetupCrowdsaleRevertWithWrongWithdrawDates(sutDatum.sut, now_ + 1 days, now_ + 2 days, 2, 1);
    expectSetupCrowdsaleRevertWithWrongWithdrawDates(
      sutDatum.sut, now_ + 1 days, now_ + 2 days, now_ + 2 days - 1 hours, 1
    );
  }

  function table_setupCrowdsale_emits_withCorrectCrowdsaleData(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);
    uint256 now_ = block.timestamp;

    ICrowdsaleable.CrowdsaleData memory expectedCrowdsaleData;
    expectedCrowdsaleData.rate = 10;
    expectedCrowdsaleData.beginSaleDate = now_ + 1 days;
    expectedCrowdsaleData.endSaleDate = now_ + 2 days;
    expectedCrowdsaleData.beginWithdrawDate = now_ + 3 days;
    expectedCrowdsaleData.endWithdrawDate = now_ + 4 days;

    vm.expectEmit();
    emit ICrowdsaleable.CrowdsaleSetup(expectedCrowdsaleData);
    setupTestCrowdsaleWith(sut, expectedCrowdsaleData);

    ICrowdsaleable.CrowdsaleData memory crowdsaleData =
      callForCrowdsaleData(sut, user, abi.encodeWithSignature("getCrowdsaleData()"));

    assertEq(10, crowdsaleData.rate);
    assertEq(now_ + 1 days, crowdsaleData.beginSaleDate);
    assertEq(now_ + 2 days, crowdsaleData.endSaleDate);
    assertEq(now_ + 3 days, crowdsaleData.beginWithdrawDate);
    assertEq(now_ + 4 days, crowdsaleData.endWithdrawDate);
  }

  function table_setupCrowdsale_throws_whenCalledAfterSaleHasBegun(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    ICrowdsaleable.CrowdsaleData memory crowdsaleData = setupTestCrowdsaleAndBeginSalePeriod(sut);

    expectCallRevert(
      ICrowdsaleable.CannotSetupAfterSaleBegin.selector,
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature(
        "setupCrowdsale(uint256,uint256,uint256,uint256,uint256)",
        crowdsaleData.rate + 10,
        crowdsaleData.beginSaleDate + 1 days,
        crowdsaleData.endSaleDate + 1 days,
        crowdsaleData.beginWithdrawDate + 1 days,
        crowdsaleData.endWithdrawDate + 1 days
      )
    );
  }

  function table_setupCrowdsale_emits_whenCalledAgainBeforeSaleStarts(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    ICrowdsaleable.CrowdsaleData memory expectedCrowdsaleData = setupTestCrowdsale(sut);
    vm.warp(expectedCrowdsaleData.beginSaleDate - 1 hours);
    uint256 now_ = block.timestamp;

    ICrowdsaleable.CrowdsaleData memory newCrowdsale;
    newCrowdsale.rate = 100;
    newCrowdsale.beginSaleDate = now_ + 1 days;
    newCrowdsale.endSaleDate = now_ + 2 days;
    newCrowdsale.beginWithdrawDate = now_ + 3 days;
    newCrowdsale.endWithdrawDate = now_ + 4 days;

    vm.expectEmit();
    emit ICrowdsaleable.CrowdsaleSetup(newCrowdsale);
    setupTestCrowdsaleWith(sut, newCrowdsale);
  }

  function table_payForToken_throws_forUnsetupCrowdsale(SUTDatum memory sutDatum) public {
    vm.deal(alice, 500 gwei);

    expectPaidCallRevert(
      ICrowdsaleable.CannotPayForTokenBeforeSetupCrowdsale.selector,
      500 gwei,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature("payForToken()")
    );
  }

  function table_payForToken_throws_forInsufficientAmount(SUTDatum memory sutDatum) public {
    ICrowdsaleable.CrowdsaleData memory crowdsale = setupTestCrowdsale(sutDatum.sut);

    vm.deal(alice, crowdsale.rate - 1);

    expectPaidCallRevert(
      ICrowdsaleable.InsufficientFunds.selector,
      crowdsale.rate - 1,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature("payForToken()")
    );
  }

  function table_payForToken_throws_ifSalePeriodHasNotStarted(SUTDatum memory sutDatum) public {
    ICrowdsaleable.CrowdsaleData memory crowdsale = setupTestCrowdsale(sutDatum.sut);
    vm.deal(alice, crowdsale.rate);

    expectPaidCallRevert(
      ICrowdsaleable.CannotPayForTokenBeforeSalePeriodHasBegun.selector,
      crowdsale.rate,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature("payForToken()")
    );
  }

  function table_payForToken_throws_ifSalePeriodHasEnded(SUTDatum memory sutDatum) public {
    ICrowdsaleable.CrowdsaleData memory crowdsale = setupTestCrowdsale(sutDatum.sut);
    vm.deal(alice, crowdsale.rate);

    vm.warp(crowdsale.endSaleDate + 2 hours);

    expectPaidCallRevert(
      ICrowdsaleable.CannotPayForTokenAfterSalePeriodHasEnded.selector,
      crowdsale.rate,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature("payForToken()")
    );
  }

  function table_payForToken_emitsAndReturnsTokenId_onSuccess(SUTDatum memory sutDatum) public {
    ICrowdsaleable.CrowdsaleData memory crowdsale = setupTestCrowdsale(sutDatum.sut);
    vm.deal(alice, crowdsale.rate);

    vm.warp(crowdsale.beginSaleDate);

    vm.expectEmit();
    emit ICrowdsaleable.PaidForToken(alice, 0);

    uint256 returnedTokenId =
      paidCallForUint256(sutDatum.sut, alice, crowdsale.rate, abi.encodeWithSignature("payForToken()"));

    assertEq(0, returnedTokenId);
  }

  function table_withdrawToken_throws_forUnsetupCrowdsale(SUTDatum memory sutDatum) public {
    expectCallRevert(
      ICrowdsaleable.CannotWithdrawTokenBeforeSetupCrowdsale.selector,
      sutDatum.sut,
      alice,
      abi.encodeWithSignature("withdrawToken(uint256)", 0)
    );
  }

  function table_withdrawToken_throws_ifUserHasNotBoughtIt(SUTDatum memory sutDatum) public {
    ICrowdsaleable.CrowdsaleData memory crowdsale = setupTestCrowdsale(sutDatum.sut);
    vm.deal(alice, crowdsale.rate);

    vm.warp(crowdsale.endWithdrawDate - 12 hours);

    expectCallRevert(
      INifty.Unauthorized.selector, sutDatum.sut, alice, abi.encodeWithSignature("withdrawToken(uint256)", 0)
    );
  }

  function table_withdrawToken_throws_ifTransferFails(SUTDatum memory sutDatum) public {
    address failingReceiver = address(new FailingReceiver());
    ICrowdsaleable.CrowdsaleData memory crowdsale = setupTestCrowdsaleAndBeginSalePeriod(sutDatum.sut);
    vm.deal(failingReceiver, crowdsale.rate);

    paidCallForUint256(sutDatum.sut, failingReceiver, crowdsale.rate, abi.encodeWithSignature("payForToken()"));

    vm.warp(crowdsale.endWithdrawDate - 2 hours);

    expectCallRevert(
      FailingReceiver.OhShit.selector,
      sutDatum.sut,
      failingReceiver,
      abi.encodeWithSignature("withdrawToken(uint256)", 0)
    );
  }

  function table_withdrawToken_emitsAndTransferTokenToBuyer_onSuccess(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;
    ICrowdsaleable.CrowdsaleData memory crowdsale = setupTestCrowdsaleAndBeginSalePeriod(sutDatum.sut);
    vm.deal(alice, crowdsale.rate);

    uint256 tokenId = paidCallForUint256(sut, alice, 500 gwei, abi.encodeWithSignature("payForToken()"));

    vm.warp(crowdsale.endWithdrawDate - 2 hours);

    vm.expectEmit();
    emit IERC721.Transfer(sut, alice, tokenId);

    callForVoid(sut, alice, abi.encodeWithSignature("withdrawToken(uint256)", tokenId));
  }

  function table_withdrawFunds_throws_ifNotCalledByOwner(SUTDatum memory sutDatum) public {
    expectCallRevert(INifty.Unauthorized.selector, sutDatum.sut, alice, abi.encodeWithSignature("withdrawFunds()"));
  }

  function table_withdrawFunds_throws_ifCrowdsaleIsNotSetup(SUTDatum memory sutDatum) public {
    expectCallRevert(
      ICrowdsaleable.CannotWithdrawFundsBeforeSetupCrowdsale.selector,
      sutDatum.sut,
      crowdsaleOwner,
      abi.encodeWithSignature("withdrawFunds()")
    );
  }

  function table_withdrawFunds_throws_ifWithdrawPeriodHasNotBegun(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    setupTestCrowdsale(sut);

    expectCallRevert(
      ICrowdsaleable.CannotWithdrawFundsBeforeWithdrawPeriodHasBegun.selector,
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature("withdrawFunds()")
    );
  }

  function table_withdrawFunds_throws_ifWithdrawPeriodHasEnded(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    setupTestCrowdsaleAndEndWithdrawPeriod(sut);

    expectCallRevert(
      ICrowdsaleable.CannotWithdrawFundsAfterWithdrawPeriodHasEnded.selector,
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature("withdrawFunds()")
    );
  }

  function xtable_withdrawFunds_throws_ifTransferFails(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    ICrowdsaleable.CrowdsaleData memory crowdsaleData = setupTestCrowdsaleAndBeginSalePeriod(sut);
    vm.deal(alice, crowdsaleData.rate);

    paidCallForUint256(sut, alice, crowdsaleData.rate, abi.encodeWithSignature("payForToken()"));

    vm.warp(crowdsaleData.endWithdrawDate - 1);

    address nonPayableContract = address(new NonPayableContract());
    callForVoid(sut, crowdsaleOwner, abi.encodeWithSignature("transferOwnership(address)", nonPayableContract));
    callForVoid(sut, nonPayableContract, abi.encodeWithSignature("acceptOwnership()"));

    expectCallRevert(
      ICrowdsaleable.WithdrawFundsTransferFailed.selector,
      sut,
      nonPayableContract,
      abi.encodeWithSignature("withdrawFunds()")
    );
  }

  function table_withdrawFunds_emits_onSuccess(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    ICrowdsaleable.CrowdsaleData memory crowdsaleData = setupTestCrowdsaleAndBeginSalePeriod(sut);
    vm.deal(alice, 1 ether);

    paidCallForUint256(sut, alice, crowdsaleData.rate, abi.encodeWithSignature("payForToken()"));
    paidCallForUint256(sut, alice, crowdsaleData.rate, abi.encodeWithSignature("payForToken()"));
    paidCallForUint256(sut, alice, crowdsaleData.rate, abi.encodeWithSignature("payForToken()"));

    vm.warp(crowdsaleData.endWithdrawDate - 1);

    uint256 sutBalanceBeforeWithdrawal = sut.balance;
    uint256 crowdsaleOwnerBalanceBeforeWithdrawal = crowdsaleOwner.balance;

    vm.expectEmit();
    emit ICrowdsaleable.FundsWithdrawn(crowdsaleOwner, sutBalanceBeforeWithdrawal);
    callForVoid(sut, crowdsaleOwner, abi.encodeWithSignature("withdrawFunds()"));

    uint256 sutBalanceAfterWithdrawal = sut.balance;

    assertLt(0, crowdsaleOwner.balance);
    assertEq(sutBalanceBeforeWithdrawal, crowdsaleOwner.balance - crowdsaleOwnerBalanceBeforeWithdrawal);
    assertEq(0, sutBalanceAfterWithdrawal);
  }

  function expectSetupCrowdsaleRevertWithWrongSaleDates(address sut, uint256 beginSale, uint256 endSale) private {
    expectCallRevert(
      ICrowdsaleable.WrongSaleDates.selector,
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature("setupCrowdsale(uint256,uint256,uint256,uint256,uint256)", 0, beginSale, endSale, 0, 0)
    );
  }

  function expectSetupCrowdsaleRevertWithWrongRate(address sut, uint256 rate) private {
    uint256 now_ = block.timestamp;

    expectCallRevert(
      ICrowdsaleable.WrongRate.selector,
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature(
        "setupCrowdsale(uint256,uint256,uint256,uint256,uint256)", rate, now_ + 1 days, now_ + 2 days, 0, 0
      )
    );
  }

  function setupTestCrowdsaleWith(address sut, ICrowdsaleable.CrowdsaleData memory crowdsaleData) private {
    callForVoid(
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature(
        "setupCrowdsale(uint256,uint256,uint256,uint256,uint256)",
        crowdsaleData.rate,
        crowdsaleData.beginSaleDate,
        crowdsaleData.endSaleDate,
        crowdsaleData.beginWithdrawDate,
        crowdsaleData.endWithdrawDate
      )
    );
  }

  function setupTestCrowdsale(address sut) private returns (ICrowdsaleable.CrowdsaleData memory) {
    uint256 now_ = block.timestamp;

    ICrowdsaleable.CrowdsaleData memory crowdsaleData;
    crowdsaleData.rate = 500 gwei;
    crowdsaleData.beginSaleDate = now_ + 1 days;
    crowdsaleData.endSaleDate = now_ + 2 days;
    crowdsaleData.beginWithdrawDate = now_ + 3 days;
    crowdsaleData.endWithdrawDate = now_ + 4 days;

    callForVoid(
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature(
        "setupCrowdsale(uint256,uint256,uint256,uint256,uint256)",
        crowdsaleData.rate,
        crowdsaleData.beginSaleDate,
        crowdsaleData.endSaleDate,
        crowdsaleData.beginWithdrawDate,
        crowdsaleData.endWithdrawDate
      )
    );

    return crowdsaleData;
  }

  function setupTestCrowdsaleAndBeginSalePeriod(address sut) private returns (ICrowdsaleable.CrowdsaleData memory) {
    ICrowdsaleable.CrowdsaleData memory crowdsaleData = setupTestCrowdsale(sut);

    vm.warp(crowdsaleData.beginSaleDate + 1 hours);

    return crowdsaleData;
  }

  function setupTestCrowdsaleAndEndWithdrawPeriod(address sut) private returns (ICrowdsaleable.CrowdsaleData memory) {
    ICrowdsaleable.CrowdsaleData memory crowdsaleData = setupTestCrowdsale(sut);

    vm.warp(crowdsaleData.endWithdrawDate + 1 hours);

    return crowdsaleData;
  }

  function expectSetupCrowdsaleRevertWithWrongWithdrawDates(
    address sut,
    uint256 beginSale,
    uint256 endSale,
    uint256 beginWithdraw,
    uint256 endWithdraw
  ) private {
    expectCallRevert(
      ICrowdsaleable.WrongWithdrawDates.selector,
      sut,
      crowdsaleOwner,
      abi.encodeWithSignature(
        "setupCrowdsale(uint256,uint256,uint256,uint256,uint256)", 10, beginSale, endSale, beginWithdraw, endWithdraw
      )
    );
  }
}
