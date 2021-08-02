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

import './IListingFactory.sol';

abstract contract ListingFactory is IListingFactory {
  constructor(address _gateKeeper) IListingFactory(_gateKeeper) {}

  function createListing(
    address _owner,
    uint256 _price,
    uint256 _stakeAmount,
    address _tcr,
    string memory _metadata
  ) public virtual override;
}
