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

import '../tokens/ERC20/IERC20Token.sol';
import '../authentication/Secured.sol';
import '../utility/metadata/IpfsFieldContainer.sol';
import './Challenge.sol';

contract IListing is Secured, IpfsFieldContainer {
  bytes32 public constant BLACKLIST_ROLE = 'BLACKLIST_ROLE';

  event Blacklisted(address listing);
  event StakeSet(address listing, uint256 stake);
  event ChallengesStakeSet(address listing, uint256 stake);
  event ChallengeSet(address listing, address challenge);
  event WhitelistedSet(address listing, bool whitelisted);
  event PriceSet(address listing, uint256 price);
  event ChallengeIDSet(address listing, uint256 challengeID);
  event NumberOfChallengesSet(address listing, uint256 numberOfChallenges);

  uint256 public price = 0;
  uint256 public stake = 0;
  uint256 public challengesStake = 0; // Total stake locked up in challenges on this listing
  uint256 public numberOfChallenges = 0; // Total number of unresolved challenges
  address[] public challenges; // Array of addresses of the challenges, needed to get them from within the TCR,
  // using the getByIndex method on the challengeRegistry

  bool public whitelisted = true; // Should the data appear on the listing or not
  address public owner;

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
  ) Secured(_gateKeeper) {
    owner = _owner;
    price = _price;
    stake = _stakeAmount;
  }

  /**
  @notice         Sets whitelisted to false: the listing should not appear anymore
  */
  function blacklist() public auth(BLACKLIST_ROLE) {
    whitelisted = false;
    emit Blacklisted(address(this));
  }

  /**
  @notice         Sets the stake
  @param _stake   Stake
  */
  function setStake(uint256 _stake) public {
    stake = _stake;
    emit StakeSet(address(this), _stake);
  }

  /**
  @notice                   Sets the amount staked for all challenged
  @param _challengesStake   Amount staked for all challenges
  */
  function setChallengesStake(uint256 _challengesStake) public {
    challengesStake = _challengesStake;
    emit ChallengesStakeSet(address(this), _challengesStake);
  }

  /**
  @notice                      Sets the muber of challenges
  @param _numberOfChallenges   Number of challenges added to this listing
  */
  function setNumberOfChallenges(uint256 _numberOfChallenges) public {
    numberOfChallenges = _numberOfChallenges;
    emit NumberOfChallengesSet(address(this), _numberOfChallenges);
  }

  /**
  @notice               Sets whether or not the listing is whitelisted
  @param _whitelisted   Whitelisted
  */
  function setWhitelisted(bool _whitelisted) public {
    whitelisted = _whitelisted;
    emit WhitelistedSet(address(this), _whitelisted);
  }

  /**
  @notice         Sets the price
  @param _price   Price
  */
  function setPrice(uint256 _price) public {
    price = _price;
    emit PriceSet(address(this), _price);
  }

  /**
  @notice             Adds a challenge to the challenges array
  @param _challenge   Address of challenge
  */
  function setChallenge(address _challenge) public {
    challenges.push(_challenge);
  }

  /**
  @notice        Gets length of the challenges array, with addresses of all challenges to this listing
  */
  function getChallengesLength() public view returns (uint256 length) {
    length = challenges.length;
  }

  /**
  @notice        Gets a challenge in the challenges array at a certain index
  @param _index  Index of the challenge
  */
  function getChallengeAtIndex(uint256 _index) public view returns (address challenge) {
    challenge = address(challenges[_index]);
  }
}
