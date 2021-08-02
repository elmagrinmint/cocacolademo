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
import './IListingFactory.sol';
import '../tokens/ERC20/IERC20Token.sol';
import '../authentication/Secured.sol';
import '../utility/syncing/Syncable.sol';
import '../utility/metadata/IpfsFieldContainer.sol';
import './Challenge.sol';
import './ChallengeRegistry.sol';

contract TokenCuratedRegistry is Secured, Syncable {
  bytes32 public constant WITHDRAW_FUNDS_ROLE = 'WITHDRAW_FUNDS_ROLE';
  bytes32 public constant CURATE_CHALLENGE_ROLE = 'CURATE_CHALLENGE_ROLE';
  bytes32 public constant CHANGE_SETTINGS_ROLE = 'CHANGE_SETTINGS_ROLE';

  // ------
  // EVENTS
  // ------

  event Enlisted(address listing, uint256 stake, uint256 price);
  event Challenged(address listing, uint256 stake, address challenge);
  event Unlisted(address listing);
  event ChallengeApproved(address listing);
  event ChallengeDenied(address listing);
  event Increased(address listing, uint256 increasedBy, uint256 newStake);
  event Decreased(address listing, uint256 decreasedBy, uint256 newStake);
  event Withdrawn(address by, uint256 balance);
  event MinEnlistAmountChanged(uint256 value);
  event MinChallengeAmountChanged(uint256 value);
  event CuratorPercentageChanged(uint256 value);

  // Maps listingHashes to associated listing data
  mapping(address => IListing) public listings;
  address[] listingsIndex;

  // Global Variables
  IERC20Token public token;
  IListingFactory public listingFactory;
  ChallengeRegistry challengeRegistry;

  // Settings
  uint256 minEnlistAmount = 0;
  uint256 minChallengeAmount = 0;
  uint256 curatorPercentage = 0;

  /**
  @dev Contructor
  @notice                Sets the address for token
  @param _gateKeeper     Address of the gatekeeper
  @param _token          Address of the token
  */
  constructor(
    address _gateKeeper,
    address _token,
    address _listingFactory,
    address _challengeRegistry,
    uint256 _minEnlistAmount,
    uint256 _minChallengeAmount,
    uint256 _curatorPercentage
  ) Secured(_gateKeeper) {
    token = IERC20Token(_token);
    listingFactory = IListingFactory(_listingFactory);
    challengeRegistry = ChallengeRegistry(_challengeRegistry);

    minEnlistAmount = _minEnlistAmount;
    minChallengeAmount = _minChallengeAmount;
    curatorPercentage = _curatorPercentage;
  }

  /**
  @notice                 Allows a seller to list data to be available for selling.
  @notice                 Takes tokens from user.
  @param _stakeAmount     The number of ERC20 tokens a user is willing to potentially stake
  @param _price           Price of the listing
  @param _metadata        Metadata
  */
  function enlist(
    uint256 _stakeAmount,
    uint256 _price,
    string calldata _metadata
  ) external {
    // Stake must be above a certain amount
    require(_stakeAmount >= minEnlistAmount, '_stakeAmount >= minEnlistAmount');

    // Transfers tokens from user to Registry contract
    require(token.transferFrom(msg.sender, address(this), _stakeAmount), 'transfer failed');

    // Add listing to listings
    listingFactory.createListing(msg.sender, _price, _stakeAmount, address(this), _metadata);
  }

  /**
  @notice                 Listing is added through the factory
  @param _listing         Address of the added listing
  */
  function addListing(address _listing) public {
    IListing listing = IListing(_listing);

    // Add to mapping
    listings[_listing] = listing;
    listingsIndex.push(_listing);

    // Event
    emit Enlisted(_listing, listing.stake(), listing.price());
  }

  /**
  @notice             Allows the owner of a listing to remove the listing from the whitelist
  @notice             Returns all tokens to the owner of the listing
  @param _listing     The listing of a user's listing
  */
  function unlist(address _listing) public {
    IListing listing = listings[_listing];
    require(msg.sender == listing.owner(), 'sender is not the owner');

    // Transfers any remaining balance back to the owner
    if (listing.stake() > 0) require(token.transfer(listing.owner(), listing.stake()), 'transfer failed');

    // Blacklist
    listing.setWhitelisted(false);

    // Event
    emit Unlisted(_listing);
  }

  /**
  @notice             Allows the owner of a listing to increase their unstaked deposit.
  @param _listing     The listing of a user's application/listing
  @param _stakeAmount The number of ERC20 tokens to increase a user's unstaked deposit
  */
  function increase(address _listing, uint256 _stakeAmount) public {
    IListing listing = listings[_listing];

    require(listing.owner() == msg.sender, 'owner is not the sender');
    require(token.transferFrom(msg.sender, address(this), _stakeAmount), 'transfer failed');

    listing.setStake(listing.stake() + _stakeAmount);

    // Event
    emit Increased(_listing, _stakeAmount, listing.stake());
  }

  /**
  @notice             Allows the owner of a listing to decrease their unstaked deposit.
  @notice             The listing keeps its previous status.
  @param _listing     The listing of a user's application/listing
  @param _stakeAmount The number of ERC20 tokens to decrease a user's unstaked deposit
  */
  function decrease(address _listing, uint256 _stakeAmount) public {
    IListing listing = listings[_listing];

    uint256 stake = listing.stake();

    require(listing.owner() == msg.sender, 'owner is not the sender');
    require(_stakeAmount <= stake, '_stakeAmount <= stake');
    require(stake - _stakeAmount >= minEnlistAmount, 'stake - _stakeAmount >= minEnlistAmount');

    require(token.transfer(msg.sender, _stakeAmount), 'transfer failed');

    listing.setStake(stake - _stakeAmount);

    // Event
    emit Decreased(_listing, _stakeAmount, listing.stake());
  }

  /**
  @notice             Starts a challenge for a listing.
  @dev                Tokens are taken from the challenger and the data seller's deposit is locked.
  @param _listing     The listing of data.
  @param _stakeAmount The amount the challenger wants to stake.
  */
  function challenge(
    address _listing,
    uint256 _stakeAmount,
    string memory _metadata
  ) public {
    require(_stakeAmount >= minChallengeAmount, '_stakeAmount >= minChallengeAmount');

    IListing listing = listings[_listing];

    // Takes tokens from challenger
    require(token.transferFrom(msg.sender, address(this), _stakeAmount), 'transfer failed');

    // Add challenge to the challenges mapping
    Challenge _challenge = new Challenge(msg.sender, _stakeAmount, _listing, address(gateKeeper));

    // Metadata role
    gateKeeper.createPermission(msg.sender, address(_challenge), bytes32('UPDATE_IPFSCONTAINERHASH_ROLE'), msg.sender);

    // Add metadata
    _challenge.setIpfsFieldContainerHash(_metadata);

    // Add challenge to registry
    challengeRegistry.addChallenge(address(_challenge));
    // Add the necessary data on the challenged listing
    listing.setChallengesStake(listing.challengesStake() + _stakeAmount);
    listing.setNumberOfChallenges(listing.numberOfChallenges() + 1);
    listing.setChallenge(address(_challenge));

    // Event
    emit Challenged(_listing, _stakeAmount, address(_challenge));
  }

  /**
  @notice             Marks a challenge as resolved.
  @notice             Rewards the winner tokens and either whitelists or de-whitelists the listing.
  @param _listing     A listing with a challenge that is to be resolved
  */
  function approveChallenge(address _listing) public auth(CURATE_CHALLENGE_ROLE) {
    IListing listing = listings[_listing];

    uint256 challengesStake = listing.challengesStake();

    // Curator (msg.sender) should get 10% of the total sum of all challenge stakes + lising stake
    uint256 curatorShare = challengesStake * (curatorPercentage / 100);
    token.transfer(msg.sender, curatorShare);

    // Challengers should get a percentage of the total sum of all challenge stakes + lising stake
    // equal to their share of the total challenge stake
    // Get all challenges that are unresolved and are linked to this listing,
    for (uint256 i = 0; i < listing.getChallengesLength(); i++) {
      Challenge _challenge = Challenge(listing.getChallengeAtIndex(i));

      if (_challenge.resolved() == false) {
        // Calculate what's left to divide between the challengers
        uint256 challengerShare = challengesStake - curatorShare;
        // Transfer percentage of challenge to THIS challenger
        token.transfer(_challenge.challenger(), challengerShare * (_challenge.stake() / challengesStake));
        // Set challenge as resolved
        _challenge.setResolved(true);
      }
    }

    // Take stake from listing
    listing.setStake(0);
    // Reset number of challenges and total challenges stake
    listing.setChallengesStake(0);
    listing.setNumberOfChallenges(0);

    // Blacklist listing
    listing.setWhitelisted(false);

    // Event
    emit ChallengeApproved(_listing);
  }

  /**
  @notice             Marks a challenge as denied.
  @notice             Rewards the listing seller tokens and de-whitelists the listing.
  @param _listing     A listing with a challenge that is to be resolved
  */
  function denyChallenge(address _listing) public auth(CURATE_CHALLENGE_ROLE) {
    IListing listing = listings[_listing];

    uint256 challengesStake = listing.challengesStake();

    // Admin (msg.sender) should get 10% of the total sum of all challenge stakes + lising stake
    uint256 curatorShare = (challengesStake * curatorPercentage) / 100;
    token.transfer(msg.sender, curatorShare);

    // Transfer the rest of the stake to the data owner
    token.transfer(listing.owner(), challengesStake - curatorShare);

    // Get all challenges that are unresolved and are linked to this listing,
    for (uint256 i = 0; i < listing.getChallengesLength(); i++) {
      Challenge _challenge = Challenge(listing.getChallengeAtIndex(i));

      if (_challenge.resolved() == false) {
        // Set challenge as resolved
        _challenge.setResolved(true);
      }
    }

    // Reset number of challenges and total challenges stake
    listing.setChallengesStake(0);
    listing.setNumberOfChallenges(0);

    // Event
    emit ChallengeDenied(_listing);
  }

  /**
  @notice      Withdraw all the funds from this contract: safety measure
  */
  function withdraw() public auth(WITHDRAW_FUNDS_ROLE) {
    uint256 balance = address(this).balance;
    token.transfer(msg.sender, address(this).balance);
    emit Withdrawn(msg.sender, balance);
  }

  /**
  @notice                   Sets the minEnlistAmount
  @param _minEnlistAmount   minEnlistAmount
  */
  function setMinEnlistAmount(uint256 _minEnlistAmount) public auth(CHANGE_SETTINGS_ROLE) {
    minEnlistAmount = _minEnlistAmount;
    emit MinEnlistAmountChanged(_minEnlistAmount);
  }

  /**
  @notice                     Sets the minChallengeAmount
  @param _minChallengeAmount  minChallengeAmount
  */
  function setMinChallengeAmount(uint256 _minChallengeAmount) public auth(CHANGE_SETTINGS_ROLE) {
    minChallengeAmount = _minChallengeAmount;
    emit MinChallengeAmountChanged(_minChallengeAmount);
  }

  /**
  @notice                   Sets the curatorPercentage
  @param _curatorPercentage curatorPercentage
  */
  function setCuratorPercentage(uint256 _curatorPercentage) public auth(CHANGE_SETTINGS_ROLE) {
    curatorPercentage = _curatorPercentage;
    emit CuratorPercentageChanged(_curatorPercentage);
  }

  /**
   * implementation of syncable methods
   */
  function getIndexLength() public view override returns (uint256 length) {
    length = listingsIndex.length;
  }

  function getByIndex(uint256 index) public view returns (address key, address contractAddress) {
    return getByKey(listingsIndex[index]);
  }

  function getByKey(address _key) public view returns (address key, address contractAddress) {
    key = address(listings[_key]);
    contractAddress = address(listings[_key]);
  }
}
