// SPDX-License-Identifier: UNLICENSED
/**
 * Copyright (C) SettleMint NV - All Rights Reserved
 *
 * Use of this file is strictly prohibited without an active license agreement.
 * Distribution of this file, via any medium, is strictly prohibited.
 *
 * For license inquiries, contact hello@settlemint.com
 */

pragma solidity ^0.8.0;

import './IListing.sol';

contract Listing is IListing {
  /**
  @dev Contructor
  @notice                Sets the address for token
  @param _owner          Address of the owner
  @param _price          Price for the listing
  @param _stakeAmount    Amount staked for the listing
  @param _gateKeeper     Address of the gatekeeper
  */
  constructor(
    address _owner,
    uint256 _price,
    uint256 _stakeAmount,
    address _gateKeeper
  ) IListing(_owner, _price, _stakeAmount, _gateKeeper) {}
}
