// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ICrowdsaleable } from "./interfaces/ICrowdsaleable.sol";
import { IInitializable } from "./interfaces/proxy/IInitializable.sol";
import { IMintable } from "./interfaces/token/IMintable.sol";

import { IERC721 } from "./interfaces/token/IERC721.sol";
import { IERC721TokenReceiver } from "./interfaces/token/IERC721TokenReceiver.sol";
import { ERC165 } from "./introspection/ERC165.sol";

contract Crowdsale is ICrowdsaleable, IInitializable, IERC721TokenReceiver, ERC165 {
  address private owner_;
  CrowdsaleData private crowdsaleData_;
  mapping(uint256 tokenId => address buyer) private boughtTokenToBuyer_;
  address private tokenContract_;

  constructor(address tokenContract) {
    owner_ = msg.sender;
    tokenContract_ = tokenContract;
  }

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

    require(msg.sender == owner_, ICrowdsaleable.Unauthorized());
    require(beginSale > now_ && endSale > now_ && beginSale < endSale, ICrowdsaleable.WrongSaleDates());
    require(rate > 0, WrongRate());
    require(beginWithdraw > endSale && endWithdraw > beginWithdraw, WrongWithdrawDates());
    require(
      crowdsaleData_.beginSaleDate == 0 || block.timestamp < crowdsaleData_.beginSaleDate,
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

    boughtTokenToBuyer_[0] = msg.sender;

    emit PaidForToken(msg.sender, 0);

    IMintable(tokenContract_).mint{ value: crowdsaleData_.rate }(address(this), 0);

    return 0;
  }

  function withdrawToken(uint256 tokenId) external {
    require(crowdsaleData_.rate > 0, CannotWithdrawTokenBeforeSetupCrowdsale());
    require(block.timestamp >= crowdsaleData_.beginWithdrawDate, CannotWithdrawTokenBeforeWithdrawPeriodHasBegun());
    require(block.timestamp < crowdsaleData_.endWithdrawDate, CannotWithdrawTokenAfterWithdrawPeriodHasEnded());
    require(msg.sender == boughtTokenToBuyer_[tokenId], Unauthorized());

    IERC721(tokenContract_).safeTransferFrom(address(this), msg.sender, tokenId);
  }
}
