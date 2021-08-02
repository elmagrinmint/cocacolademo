// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../authentication/Secured.sol';
import './IERC777TokenRecipient.sol';
import './IERC777TokenSender.sol';
import './IERC777Token.sol';

abstract contract ERC777Token is IERC777Token, Secured {
  string public _name;
  string public _symbol;
  uint256 public _totalSupply;
  uint256 public _granularity;

  mapping(address => uint256) private balances;
  mapping(address => mapping(address => bool)) private operators;

  constructor(
    string memory name,
    string memory symbol,
    uint256 granularity
  ) {
    _name = name;
    _symbol = symbol;
    _totalSupply = 0;
    require(granularity >= 1, 'The smallest unit must be greater than or equal to 1');
    _granularity = granularity;
  }

  /**
   * Get the balance for a given address
   * @param owner token owner
   */
  function balanceOf(address owner) public view override returns (uint256) {
    return balances[owner];
  }

  /**
   * Mint a certain amount of tokens for a certain address
   */
  function mint(address to, uint256 amount) public auth(MINT_ROLE) {
    require(isOperatorFor(msg.sender, to), 'Only operators can mint tokens');
    require(isGranular(uint256(amount)), 'Only amounts which are a multiple of the granularity are allowed');

    _totalSupply = _totalSupply + (amount);
    balances[to] = balances[to] + (amount);

    emit Minted(msg.sender, to, amount, '');
  }

  /**
   * Burn a certain amount of tokens for a certain address
   */
  function burn(address from, uint256 amount) public auth(BURN_ROLE) {
    require(isOperatorFor(msg.sender, from), 'Only operators can burn tokens');
    require(isGranular(amount), 'Only amounts which are a multiple of the granularity are allowed');
    require(amount > 0, 'Amount should be bigger than 0');
    require(amount <= balances[from], 'Account balance should be sufficient');

    balances[from] = balances[from] - (amount);
    _totalSupply = _totalSupply - (amount);

    emit Burned(msg.sender, from, amount, '', '');
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
   * Authorize the given operator full control over the msg.sender's tokens
   */
  function authorizeOperator(address operator) public override {
    require(operator != msg.sender, 'The owner of the tokens is by default authorized');
    operators[msg.sender][operator] = true;
    emit AuthorizedOperator(operator, msg.sender);
  }

  /**
   * Authorize the given operator full control over the tokenholder's tokens
   */
  function authorizeOperator(address operator, address tokenHolder) public auth(MANAGE_OPERATOR_ROLE) {
    operators[tokenHolder][operator] = true;
    emit AuthorizedOperator(operator, tokenHolder);
  }

  /**
   * Revoke the given operator's full control over the msg.sender's tokens
   */
  function revokeOperator(address operator) public override {
    require(operator != msg.sender, 'The owner of the tokens is by default authorized');
    operators[msg.sender][operator] = false;
    emit RevokedOperator(operator, msg.sender);
  }

  /**
   * Revoke the given operator's full control over tokenholder's tokens
   */
  function revokeOperator(address operator, address tokenHolder) public auth(MANAGE_OPERATOR_ROLE) {
    operators[tokenHolder][operator] = false;
    emit RevokedOperator(operator, tokenHolder);
  }

  /**
   * Get a boolean indicating if the given operator address is operator of the given tokenholder
   */
  function isOperatorFor(address operator, address tokenHolder) public view override returns (bool) {
    return operator == tokenHolder || operators[tokenHolder][operator];
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
    require(isOperatorFor(msg.sender, from), 'Only operators can send tokens');
    require(isGranular(amount), 'Only amounts which are a multiple of the granularity are allowed');
    require(to != address(0), 'Only send to valid addresses');
    require(balances[from] >= amount, 'Ensure sender has sufficient balance');

    IERC777TokenSender(from).tokensToSend(msg.sender, from, to, amount, userData, operatorData);

    balances[from] = balances[from] - (amount);
    balances[to] = balances[to] + (amount);

    IERC777TokenRecipient(to).tokensReceived(msg.sender, from, to, amount, userData, operatorData);

    emit Sent(msg.sender, from, to, amount, userData, operatorData);
  }

  /**
   * Check if the given amount is a multiple of the contract's granularity.
   */
  function isGranular(uint256 amount) internal view returns (bool) {
    return (amount / (_granularity)) * (_granularity) == amount;
  }
}
