// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../../authentication/Secured.sol';
import '../ERC777/IERC777Token.sol';
import '../ERC777/IERC777TokenRecipient.sol';
import '../ERC777/IERC777TokenSender.sol';
import './IERC1410Token.sol';

contract ERC1410Token is IERC777Token, IERC1410Token, Secured, Ownable {
  uint256 public _granularity;
  uint256 public totalSupply;
  address[] public tokenHolders;

  mapping(address => uint256) internal seen;
  mapping(address => bytes32[]) internal _tranches;
  mapping(address => bytes32[]) internal defaultTranches;
  mapping(address => mapping(bytes32 => uint256)) internal balancesByTranche;
  mapping(address => mapping(bytes32 => address[])) internal pDefaultOperatorsByTranche;
  mapping(address => mapping(bytes32 => mapping(address => bool))) internal operatorsByTranche;

  constructor(address gateKeeper, uint256 granularity) Secured(gateKeeper) {
    require(granularity >= 1, 'The smalles unit for interaction with this contract must be greater than or equal to 1');
    _granularity = granularity;
    totalSupply = 0;
  }

  /**
   * Get the balance for a given address
   * @param tokenHolder token owner
   */
  function balanceOf(address tokenHolder) public view override(IERC1410Token, IERC777Token) returns (uint256) {
    uint256 balance = 0;
    for (uint256 i = 0; i < _tranches[tokenHolder].length; i++) {
      balance = balance + (balancesByTranche[tokenHolder][_tranches[tokenHolder][i]]);
    }
    return balance;
  }

  /**
   * Get balance for given token holder by tranche
   */
  function balanceOfByTranche(bytes32 tranche, address tokenHolder) public view override returns (uint256) {
    return balancesByTranche[tokenHolder][tranche];
  }

  /**
   * Mint a certain amount of tokens for a certain address
   */
  function mint(address to, uint256 amount) public auth(MINT_ROLE) {
    if (seen[to] == 0) {
      tokenHolders.push(to);
      seen[to] = block.timestamp;
    }

    bytes32 tranche = getDefaultTranche(to);
    mint(tranche, to, amount);
  }

  /**
   * Mint a certain amount of tokens for a certain address into a tranche
   */
  function mint(
    bytes32 tranche,
    address to,
    uint256 amount
  ) public auth(MINT_ROLE) {
    require(isOperatorForTranche(tranche, msg.sender, to), 'Only operators can mint tokens');
    require(isGranular(uint256(amount)), 'Only amounts which are a multiple of the granularity are allowed');

    if (seen[to] == 0) {
      tokenHolders.push(to);
      seen[to] = block.timestamp;
    }

    totalSupply = totalSupply + (amount);
    balancesByTranche[to][tranche] = balancesByTranche[to][tranche] + (amount);

    emit Minted(msg.sender, to, amount, '');
  }

  /**
   * Burn a certain amount of tokens for a certain address
   */
  function burn(address from, uint256 amount) public auth(BURN_ROLE) {
    bytes32 tranche = getDefaultTranche(from);
    burn(tranche, from, amount);
  }

  /**
   * Burn a certain amount of tokens for a certain address
   */
  function burn(
    bytes32 tranche,
    address from,
    uint256 amount
  ) public auth(BURN_ROLE) {
    require(isOperatorForTranche(tranche, msg.sender, from), 'Only operators can burn tokens');
    require(isGranular(amount), 'Only amounts which are a multiple of the granularity are allowed');
    require(amount > 0, 'Amount should be bigger than 0');
    require(amount <= balancesByTranche[from][tranche], 'Account balance should be sufficient');

    balancesByTranche[from][tranche] = balancesByTranche[from][tranche] - (amount);
    totalSupply = totalSupply - (amount);

    emit Burned(msg.sender, from, amount, '', '');
  }

  /**
   * Get default operators for given tranche
   */
  function defaultOperatorsByTranche(bytes32 tranche) public view override returns (address[] memory) {
    return pDefaultOperatorsByTranche[msg.sender][tranche];
  }

  /**
   * Authorize the given operator full control over the msg.sender's tokens
   */
  function authorizeOperator(address operator) public override {
    bytes32 tranche = getDefaultTranche(msg.sender);
    authorizeOperatorByTranche(tranche, operator);
  }

  /**
   * Authorize the given operator full control over the tokenholder's tokens
   */
  function authorizeOperator(address operator, address tokenHolder) public auth(MANAGE_OPERATOR_ROLE) {
    bytes32 tranche = getDefaultTranche(msg.sender);
    authorizeOperatorByTranche(tranche, operator, tokenHolder);
  }

  /**
   * Authorize the given operator full control over the msg.sender's tokens for a given tranche
   */
  function authorizeOperatorByTranche(bytes32 tranche, address operator) public override {
    require(operator != msg.sender, 'The owner of the tokens is by default authorized');
    operatorsByTranche[msg.sender][tranche][operator] = true;
    emit AuthorizedOperator(operator, msg.sender);
    emit AuthorizedOperatorByTranche(tranche, operator, msg.sender);
  }

  /**
   * Authorize the given operator full control over the tokenholder's tokens for a given tranche
   */
  function authorizeOperatorByTranche(
    bytes32 tranche,
    address operator,
    address tokenHolder
  ) public auth(MANAGE_OPERATOR_ROLE) {
    operatorsByTranche[tokenHolder][tranche][operator] = true;
    emit AuthorizedOperator(operator, tokenHolder);
    emit AuthorizedOperatorByTranche(tranche, operator, msg.sender);
  }

  /**
   * Revoke the given operator's full control over the msg.sender's tokens
   */
  function revokeOperator(address operator) public override {
    bytes32 tranche = getDefaultTranche(msg.sender);
    revokeOperatorByTranche(tranche, operator);
  }

  /**
   * Revoke the given operator's full control over tokenholder's tokens
   */
  function revokeOperator(address operator, address tokenHolder) public auth(MANAGE_OPERATOR_ROLE) {
    bytes32 tranche = getDefaultTranche(msg.sender);
    revokeOperatorByTranche(tranche, operator, tokenHolder);
  }

  /**
   * Revoke the given operator's full control over tokenholder's tokens for a given tranche
   */
  function revokeOperatorByTranche(bytes32 tranche, address operator) public override {
    require(operator != msg.sender, 'The owner of the tokens is by default authorized');
    operatorsByTranche[msg.sender][tranche][operator] = false;
    emit RevokedOperator(operator, msg.sender);
    emit RevokedOperatorByTranche(tranche, operator, msg.sender);
  }

  /**
   * Revoke the given operator's full control over tokenholder's tokens for a given tranche
   */
  function revokeOperatorByTranche(
    bytes32 tranche,
    address operator,
    address tokenHolder
  ) public auth(MANAGE_OPERATOR_ROLE) {
    operatorsByTranche[msg.sender][tranche][operator] = false;
    emit RevokedOperator(operator, tokenHolder);
    emit RevokedOperatorByTranche(tranche, operator, msg.sender);
  }

  /**
   * Get a boolean indicating if the given operator address is operator of the given tokenholder
   */
  function isOperatorFor(address operator, address tokenHolder) public view override returns (bool) {
    bytes32 tranche = getDefaultTranche(tokenHolder);
    return isOperatorForTranche(tranche, operator, tokenHolder);
  }

  /**
   * Get a boolean indicating if the given operator address is operator of the given tokenholder, for a given tranche
   */
  function isOperatorForTranche(
    bytes32 tranche,
    address operator,
    address tokenHolder
  ) public view override returns (bool) {
    return operator == this.owner() || operatorsByTranche[tokenHolder][tranche][operator];
  }

  /**
   * Send a certain amount of tokens to a certain address
   */
  function send(address to, uint256 amount) public override {
    return send(to, amount, '');
  }

  /**
   * Send a certain amount of tokens to a certain address
   */
  function send(
    address to,
    uint256 amount,
    bytes memory userData
  ) public override {
    return operatorSend(msg.sender, to, amount, userData, '');
  }

  /**
   * Effectively sends the tokens and emits the proper events
   */
  function operatorSend(
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) public override {
    bytes32 tranche = getDefaultTranche(from);
    operatorSendByTranche(tranche, from, to, amount, userData, operatorData);
  }

  function sendByTranche(
    bytes32 tranche,
    address to,
    uint256 amount,
    bytes memory data
  ) public override returns (bytes32) {
    return operatorSendByTranche(tranche, msg.sender, to, amount, data, '');
  }

  function sendByTranches(
    bytes32[] memory tranches,
    address to,
    uint256[] memory amounts,
    bytes memory data
  ) public override returns (bytes32[] memory tr) {
    return operatorSendByTranches(tranches, msg.sender, to, amounts, data, '');
  }

  function operatorSendByTranche(
    bytes32 tranche,
    address from,
    address to,
    uint256 amount,
    bytes memory data,
    bytes memory operatorData
  ) public override returns (bytes32 tr) {
    bytes32[] memory tranches = new bytes32[](1);
    tranches[0] = tranche;

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;

    operatorSendByTranches(tranches, from, to, amounts, data, operatorData);
  }

  function operatorSendByTranches(
    bytes32[] memory tranches,
    address from,
    address to,
    uint256[] memory amounts,
    bytes memory data,
    bytes memory operatorData
  ) public override returns (bytes32[] memory tr) {
    require(tranches.length == amounts.length, 'No 1-1 match between tranches and amounts');
    require(to != address(0), 'Only send to valid addresses');

    if (seen[to] == 0) {
      tokenHolders.push(to);
      seen[to] = block.timestamp;
    }

    for (uint256 i = 0; i < tranches.length; i++) {
      bytes32 tranche = tranches[i];
      uint256 amount = amounts[i];

      require(isOperatorForTranche(tranche, msg.sender, from), 'Only operators can send tokens');
      require(isGranular(amount), 'Only amounts which are a multiple of the granularity are allowed');
      require(balancesByTranche[from][tranche] >= amount, 'Ensure sender has sufficient balance');

      // IERC777TokenSender(_from).tokensToSend(
      //   msg.sender,
      //   _from,
      //   _to,
      //   amount,
      //   _data,
      //   _operatorData
      // );

      balancesByTranche[from][tranche] = balancesByTranche[from][tranche] - (amount);
      balancesByTranche[to][tranche] = balancesByTranche[to][tranche] + (amount);

      // IERC777TokenRecipient(_to).tokensReceived(
      //   msg.sender,
      //   _from,
      //   _to,
      //   amount,
      //   _data,
      //   _operatorData
      // );

      emit Sent(msg.sender, from, to, amount, data, operatorData);

      emit SentByTranche(tranche, msg.sender, from, to, amount, data, operatorData);
    }
  }

  /**
   * Check if tokenholder has a tranche
   */
  function hasTranche(address tokenHolder, bytes32 tranche) public view override returns (bool) {
    for (uint256 i = 0; i < _tranches[tokenHolder].length; i++) {
      if (_tranches[tokenHolder][i] == tranche) {
        return true;
      }
    }
    return false;
  }

  /**
   * Set default tranches for a certain tokenholder
   */
  function addTranche(address tokenHolder, bytes32 tranche) public override {
    if (!hasTranche(tokenHolder, tranche)) {
      _tranches[tokenHolder].push(tranche);
    }
  }

  /**
   * Get tranches for a certain tokenholder
   */
  function tranchesOf(address tokenHolder) public view override returns (bytes32[] memory tranches) {
    return _tranches[tokenHolder];
  }

  /**
   * Get default tranches for a certain tokenholder
   */
  function getDefaultTranches(address tokenHolder) public view override returns (bytes32[] memory tranches) {
    return defaultTranches[tokenHolder];
  }

  /**
   * Get default tranche for a certain tokenholder
   */
  function getDefaultTranche(address tokenHolder) public view returns (bytes32 tranche) {
    return defaultTranches[tokenHolder][0];
  }

  /**
   * Set default tranches for a certain tokenholder
   */
  function setDefaultTranches(bytes32[] memory tranches) public override {
    defaultTranches[msg.sender] = tranches;
    _tranches[msg.sender] = tranches;
  }

  /**
   * Check if the given amount is a multiple of the contract's granularity.
   */
  function isGranular(uint256 amount) internal view returns (bool) {
    return (amount / (_granularity)) * (_granularity) == amount;
  }
}
