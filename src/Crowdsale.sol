// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ICrowdsaleable } from "./interfaces/ICrowdsaleable.sol";

import { INifty } from "./interfaces/INifty.sol";
import { IInitializable } from "./interfaces/proxy/IInitializable.sol";
import { IMintable } from "./interfaces/token/IMintable.sol";

import { IERC165 } from "./interfaces/introspection/IERC165.sol";
import { IERC721 } from "./interfaces/token/IERC721.sol";
import { IERC721Enumerable } from "./interfaces/token/IERC721Enumerable.sol";
import { IERC721TokenReceiver } from "./interfaces/token/IERC721TokenReceiver.sol";

import { ERC165 } from "./introspection/ERC165.sol";

contract Crowdsale is ICrowdsaleable, IInitializable, IERC721TokenReceiver, ERC165 {
  address private owner_;
  CrowdsaleData private crowdsaleData_;
  mapping(uint256 tokenId => address buyer) private boughtTokenToBuyer_;
  address private tokenContract_;

  constructor(address contract_) {
    owner_ = msg.sender;

    try IERC165(contract_).supportsInterface(type(IERC165).interfaceId) returns (bool supportsIERC165) {
      require(supportsIERC165, WrongTokenContract());
    } catch (bytes memory) {
      revert WrongTokenContract();
    }

    require(IERC165(contract_).supportsInterface(type(IERC721).interfaceId), WrongTokenContract());
    require(IERC165(contract_).supportsInterface(type(IMintable).interfaceId), WrongTokenContract());

    tokenContract_ = contract_;
  }

  function tokenContract() external view returns (address) {
    return tokenContract_;
  }

  // BUG: IInitializable MUST ensure initialize is called only once.
  function initialize(bytes calldata data) external {
    (owner_, tokenContract_) = abi.decode(data, (address, address));
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == type(IInitializable).interfaceId || interfaceId == type(IERC721TokenReceiver).interfaceId
      || super.supportsInterface(interfaceId);
  }

  function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
    return IERC721TokenReceiver.onERC721Received.selector;
  }

  function setupCrowdsale(uint256 rate, uint256 beginSale, uint256 endSale, uint256 beginWithdraw, uint256 endWithdraw)
    external
  {
    uint256 now_ = block.timestamp;

    require(msg.sender == owner_, INifty.Unauthorized());
    require(beginSale > now_ && endSale > beginSale, ICrowdsaleable.WrongSaleDates());
    require(rate > 0, WrongRate());
    require(beginWithdraw > endSale && endWithdraw > beginWithdraw, WrongWithdrawDates());
    require(
      crowdsaleData_.beginSaleDate == 0 || now_ < crowdsaleData_.beginSaleDate,
      ICrowdsaleable.CannotSetupAfterSaleBegin()
    );

    crowdsaleData_.rate = rate;
    crowdsaleData_.beginSaleDate = beginSale;
    crowdsaleData_.endSaleDate = endSale;
    crowdsaleData_.beginWithdrawDate = beginWithdraw;
    crowdsaleData_.endWithdrawDate = endWithdraw;

    emit CrowdsaleSetup(crowdsaleData_);
  }

  function getCrowdsaleData() external view returns (CrowdsaleData memory) {
    return crowdsaleData_;
  }

  function payForToken() external payable returns (uint256) {
    require(crowdsaleData_.rate > 0, CannotPayForTokenBeforeSetupCrowdsale());
    require(msg.value >= crowdsaleData_.rate, InsufficientFunds());
    require(block.timestamp >= crowdsaleData_.beginSaleDate, CannotPayForTokenBeforeSalePeriodHasBegun());
    require(block.timestamp < crowdsaleData_.endSaleDate, CannotPayForTokenAfterSalePeriodHasEnded());

    uint256 nextTokenId = IERC721Enumerable(tokenContract_).totalSupply();

    boughtTokenToBuyer_[nextTokenId] = msg.sender;

    emit PaidForToken(msg.sender, nextTokenId);

    IMintable(tokenContract_).mint(address(this), nextTokenId);

    return nextTokenId;
  }

  function withdrawToken(uint256 tokenId) external {
    require(crowdsaleData_.rate > 0, CannotWithdrawTokenBeforeSetupCrowdsale());
    require(msg.sender == boughtTokenToBuyer_[tokenId], INifty.Unauthorized());

    IERC721(tokenContract_).safeTransferFrom(address(this), msg.sender, tokenId);
  }

  function withdrawFunds() external {
    require(msg.sender == owner_, INifty.Unauthorized());
    require(crowdsaleData_.rate > 0, CannotWithdrawFundsBeforeSetupCrowdsale());
    require(block.timestamp >= crowdsaleData_.beginWithdrawDate, CannotWithdrawFundsBeforeWithdrawPeriodHasBegun());
    require(block.timestamp < crowdsaleData_.endWithdrawDate, CannotWithdrawFundsAfterWithdrawPeriodHasEnded());

    uint256 balance = address(this).balance;

    emit FundsWithdrawn(owner_, balance);

    payable(owner_).transfer(balance);
  }
}
