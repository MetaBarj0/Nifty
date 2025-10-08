// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { INifty } from "../../src/interfaces/INifty.sol";

import { Test } from "forge-std/Test.sol";

import { FailingReceiver, InvalidReceiver, NonCompliantReceiver, ValidReceiver } from "../Mocks.sol";
import { NiftyTestUtils, SUTDatum } from "../NiftyTestUtils.sol";

contract ERC721TokenReceiverTests is Test, NiftyTestUtils {
  address private alice;
  InvalidReceiver private invalidReceiver;
  FailingReceiver private failingReceiver;
  NonCompliantReceiver private nonCompliantReceiver;
  ValidReceiver private validReceiver;

  function setUp() public {
    invalidReceiver = new InvalidReceiver();
    failingReceiver = new FailingReceiver();
    nonCompliantReceiver = new NonCompliantReceiver();
    validReceiver = new ValidReceiver();
    alice = makeAddr("Alice");
  }

  function fixtureSutDatum() public view returns (SUTDatum[] memory) {
    return getSutDataForNifty();
  }

  function table_mint_throws_withInvalidReceiverContract(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    authorizeMinter(sut, address(invalidReceiver), true);

    vm.expectPartialRevert(INifty.InvalidReceiver.selector);
    paidMint(sut, address(invalidReceiver), 0);
  }

  function table_mint_throws_withFailingReceiverContract(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    authorizeMinter(sut, address(failingReceiver), true);

    vm.expectRevert(FailingReceiver.OhShit.selector);
    paidMint(sut, address(failingReceiver), 0);
  }

  function table_mint_throws_withNonCompliantReceiverContract(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    authorizeMinter(sut, address(nonCompliantReceiver), true);

    vm.expectPartialRevert(INifty.InvalidReceiver.selector);
    paidMint(sut, address(nonCompliantReceiver), 0);
  }

  function table_safeTransferFrom_throws_withInvalidReceiverContract(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    vm.expectPartialRevert(INifty.InvalidReceiver.selector);
    callForVoid(
      sut,
      alice,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, address(invalidReceiver), 0)
    );
  }

  function table_safeTransferFrom_throws_withFailingReceiverContract(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    vm.expectRevert();
    callForVoid(
      sut,
      alice,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, address(failingReceiver), 0)
    );
  }

  function table_safeTransferFrom_throws_withNonCompliantReceiverContract(SUTDatum memory sutDatum) public {
    address sut = sutDatum.sut;

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    vm.expectRevert();
    callForVoid(
      sut,
      alice,
      abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, address(nonCompliantReceiver), 0)
    );
  }

  function table_mint_succeeds_WithValidReceiverContract(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, address(validReceiver), true);

    vm.expectEmit();
    emit ValidReceiver.Received(address(validReceiver), address(0), 0);
    paidMint(sut, address(validReceiver), 0);

    assertEq(1, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", validReceiver)));
  }

  function table_safeTransferFrom_succeeds_withValidReceiverContract(SUTDatum memory sutDatum) public {
    (address sut, address user) = (sutDatum.sut, sutDatum.user);

    authorizeMinter(sut, alice, true);
    paidMint(sut, alice, 0);

    vm.expectEmit();
    emit ValidReceiver.Received(alice, alice, 0);
    callForVoid(
      sut,
      alice,
      abi.encodeWithSignature(
        "safeTransferFrom(address,address,uint256,bytes)", alice, address(validReceiver), 0, "validReceiver test"
      )
    );

    assertEq(1, callForUint256(sut, user, abi.encodeWithSignature("balanceOf(address)", validReceiver)));
  }
}
