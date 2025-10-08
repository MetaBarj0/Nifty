// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @notice Interface defining a crowd sale feature
 */
interface ICrowdsaleable {
  /*
   * @notice Contains all crowdsale data.
   * @dev Used in getter and event triggering
   */
  struct CrowdsaleData {
    /// @notice the a token is sold for `rate` wei
    uint256 rate;
    /// @notice begin of the sale period, must be in the future
    uint256 beginSaleDate;
    /// @notice end of the sale period, must be after the begin of the sale
    ///  period
    uint256 endSaleDate;
    /// @notice begin of the withdraw period. Must be after the end sale date
    uint256 beginWithdrawDate;
    /// @notice end of the withdraw period. Must be after the withdraw period
    uint256 endWithdrawDate;
  }

  /*
   * @notice setup the crowd sale. This is mandatory before opening the
   *         possibility for users to buy handled tokens as well as for owner
   *         to withdraw gains.
   *         See CrowdsaleData member description for arguments
   * @dev MUST throw for any invalid input
   *      - wrong begin or end sale time
   *      - wrong begin or end withdraw time
   *      MUST throw if not called by owner
   *      MUST throw if sale time or withdraw time is reached or over
   *      MUST emit CrowdsaleSetup event on success
   */
  function setupCrowdsale(uint256 rate, uint256 beginSale, uint256 endSale, uint256 beginWithdraw, uint256 endWithdraw)
    external;

  /*
     * @notice returns crowdsale data
     * @return a copy of crowdsale data within a struct
     */
  function getCrowdsaleData() external view returns (CrowdsaleData memory);

  /*
   * @notice A user can pay to get a token. The price depends on the rate setup
   *         in a successul setupCrowdsale function call.
   * @dev MUST throw if setupCrowdsale has not been successfully called
   *      beforehand
   *      MUST throw if value is lesser than the one specified in
   *      CrowdsaleData.rate
   *      MUST throw if payment is unsuccessful (only for ERC20 transfer that
   *      are not yet supported)
   *      MUST throw if sale period has not started
   *      MUST throw if sale period has ended
   *      MUST emit a TokenBought event on success
   * @return the token id the user can withdraw later on
   */
  function payForToken() external payable returns (uint256);

  /*
   * @notice allow a valid user to withdraw a previously bought token
   * @dev MUST throw if setupCrowdsale has not been successfully called
   *      beforehand
   *      MUST throw if withdraw is attempted outside of setup withdraw date
   *      range
   *      MUST throw if the user has not bought the specified token
   *      MUST throw if token transfer fails
   *      MUST emit a TokenWithdrawn event on success
   * @param tokenId the token to withdraw to the sender balance
   */
  function withdrawToken(uint256 tokenId) external;

  /*
   * @notice thrown in case of unauthorized access in a ICrowdsaleable function
   *         call
   */
  error Unauthorized(); // TODO: do not redefine INifty.Unauthorized

  /*
   * @notice Thrown when setupCrowdsale is called with incorrect sale dates
   */
  error WrongSaleDates();

  /*
   * @notice Thrown when setupCrowdsale is called with incorrect rate
   */
  error WrongRate();

  /*
   * @notice Thrown when setupCrowdsale is called with incorrect withdraw dates
   */
  error WrongWithdrawDates();

  /*
   * @notice Thrown when calling setupCrowdsale after the sale has begun
   */
  error CannotSetupAfterSaleBegin();

  /*
   * @notice Thrown if an user attempt to pay for a token before a successful
   *         call to setupCrowdsale
   */
  error CannotPayForTokenBeforeSetupCrowdsale();

  /*
   * @notice thrown when a user attempt to buy a token too low
   */
  error InsufficientFunds();

  /*
   * @notice thrown when attempting to buy tokens before the sale period has
   *         begun
   */
  error CannotPayForTokenBeforeSalePeriodHasBegun();

  /*
   * @notice thrown when attempting to buy tokens after the sale period has
   *         ended
   */
  error CannotPayForTokenAfterSalePeriodHasEnded();

  /*
   * @notice Thrown if an user attempt to withdraw a token before a successful
   *         call to setupCrowdsale
   */
  error CannotWithdrawTokenBeforeSetupCrowdsale();

  /*
   * @notice thrown when attempting to withdraw tokens before the withdraw
   *         period has begun
   */
  error CannotWithdrawTokenBeforeWithdrawPeriodHasBegun();

  /*
   * @notice thrown when attempting to withdraw tokens after the withdraw
   *         period has ended
   */
  error CannotWithdrawTokenAfterWithdrawPeriodHasEnded();

  /*
   * @notice emitted after a successfull crowdsale setup
   * @param crowdSaleData data related to the setup crowdsale
   */
  event CrowdsaleSetup(CrowdsaleData crowdsaleData);

  /*
   * @notice emitted when a token is successfully bought in payForToken
   * @param buyer the buyer address
   * @param tokenId the bought token identifier
   */
  event PaidForToken(address indexed buyer, uint256 tokenId);

  /*
   * @notice emitted when a token is successfully withdrawn in withdrawToken
   * @param owner the owner address
   * @param tokenId the withdrawn token identifier
   */
  event WithdrawnToken(address indexed owner, uint256 tokenId);
}
