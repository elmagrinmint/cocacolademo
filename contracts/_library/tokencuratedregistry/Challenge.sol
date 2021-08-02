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

import '../authentication/Secured.sol';
import '../utility/metadata/IpfsFieldContainer.sol';

contract Challenge is Secured, IpfsFieldContainer {
  event ResolvedSet(address challenge, bool resoved);

  address public challenger;
  bool public resolved = false;
  uint256 public stake;
  address public listing;
  uint256 public timestamp;

  /**
  @dev Contructor
  @notice                     Hold one challenge to a listing
  @param _challenger          Owner of Challenge
  @param _stakeAmount         Number of tokens at risk for either party during challenge
  @param _listing             Listing this challenge was added to
  @param _gateKeeper          Address of the gatekeeper
  */
  constructor(
    address _challenger,
    uint256 _stakeAmount,
    address _listing,
    address _gateKeeper
  ) Secured(_gateKeeper) IpfsFieldContainer() {
    challenger = _challenger;
    stake = _stakeAmount;
    listing = _listing;
    timestamp = block.timestamp;
  }

  /**
  @notice            Sets resolved property
  @param _resolved   Resolved
  */
  function setResolved(bool _resolved) public {
    resolved = _resolved;
    emit ResolvedSet(address(this), _resolved);
  }
}
