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
import '../utility/syncing/Syncable.sol';
import './Challenge.sol';

contract ChallengeRegistry is Secured, Syncable {
  event ChallengeAdded(address _address);

  // Keep track of challenges
  mapping(address => Challenge) public challenges;
  address[] public challengesIndex; // Array of challenge ids

  constructor(address _gateKeeper) Secured(_gateKeeper) {}

  /**
  @notice             Adds a challenge to the registry
  @param _challenge   Address of the challenge to add
  */
  function addChallenge(address _challenge) public {
    challenges[_challenge] = Challenge(address(_challenge));
    challengesIndex.push(_challenge);
    emit ChallengeAdded(_challenge);
  }

  /**
   * implementation of syncable methods
   */
  function getIndexLength() public view override returns (uint256 length) {
    length = challengesIndex.length;
  }

  function getByIndex(uint256 index) public view returns (address key, address contractAddress) {
    return getByKey(challengesIndex[index]);
  }

  function getByKey(address _key) public view returns (address key, address contractAddress) {
    key = address(challenges[_key]);
    contractAddress = address(challenges[_key]);
  }
}
