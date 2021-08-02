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

import './IERC20Token.sol';
import '../IApproveAndCallable.sol';
import '../IWithDecimalFields.sol';
import '../../authentication/RoleRegistry.sol';

abstract contract ERC20Token is IERC20Token, IWithDecimalFields {
  struct TokenAccount {
    uint256 balance;
    uint256 firstTransaction;
  }

  mapping(address => TokenAccount) balances;
  address[] tokenHolders;
  mapping(address => mapping(address => uint256)) internal allowed;
  uint256 public totalSupply;

  string public _uiFieldDefinitionsHash;

  constructor(
    string memory name,
    uint8 decimals,
    address gateKeeper,
    string memory uiFieldDefinitionsHash
  ) IERC20Token(name, decimals, gateKeeper) {
    _uiFieldDefinitionsHash = uiFieldDefinitionsHash;
  }

  function mint(address to, uint256 amount)
    public
    virtual
    override
    authWithCustomReason(MINT_ROLE, 'Sender needs the MINT__ROLE')
    returns (bool success)
  {
    if (balances[to].firstTransaction == 0) {
      balances[to].firstTransaction = block.timestamp;
      tokenHolders.push(to);
    }
    totalSupply += amount;
    balances[to].balance += amount;
    emit Mint(to, amount);
    emit Transfer(address(0x0), to, amount);
    return true;
  }

  function mintToRoleRegistry(address roleRegistryAddress, uint256 amount)
    public
    virtual
    override
    authWithCustomReason(MINT_ROLE, 'Sender needs the MINT__ROLE')
    returns (bool success)
  {
    RoleRegistry roleRegistry = RoleRegistry(roleRegistryAddress);
    uint256 numberOfUsers = roleRegistry.getIndexLength();
    for (uint256 counter = 0; counter < numberOfUsers; counter++) {
      address holder;
      bool hasRole;
      (holder, hasRole) = roleRegistry.getByIndex(counter);
      if (hasRole) {
        mint(holder, amount);
      }
    }
    return true;
  }

  function burn(address from, uint256 amount)
    public
    virtual
    override
    authWithCustomReason(BURN_ROLE, 'Sender needs the BURN_ROLE')
    returns (bool success)
  {
    require(amount > 0, 'amount should be bigger than 0');
    require(amount <= balances[from].balance, 'amount should be less than balance');
    balances[from].balance -= amount;
    totalSupply -= amount;
    emit Burn(from, amount);
    emit Transfer(from, address(0x0), amount);
    return true;
  }

  function burnFromRoleRegistry(address roleRegistryAddress, uint256 amount)
    public
    virtual
    override
    authWithCustomReason(BURN_ROLE, 'Sender needs the BURN_ROLE')
    returns (bool success)
  {
    RoleRegistry roleRegistry = RoleRegistry(roleRegistryAddress);
    uint256 numberOfUsers = roleRegistry.getIndexLength();
    for (uint256 counter = 0; counter < numberOfUsers; counter++) {
      address holder;
      bool hasRole;
      (holder, hasRole) = roleRegistry.getByIndex(counter);
      if (hasRole) {
        burn(holder, amount);
      }
    }
    return true;
  }

  function transfer(address to, uint256 value) public virtual override returns (bool success) {
    require(to != address(0), 'to should not be 0');
    require(value <= balances[msg.sender].balance, 'value should be less than balance');

    if (balances[to].firstTransaction == 0) {
      balances[to].firstTransaction = block.timestamp;
      tokenHolders.push(to);
    }

    balances[msg.sender].balance -= value;
    balances[to].balance += value;
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferWithData(
    address to,
    uint256 value,
    bytes memory data
  ) public virtual override returns (bool success) {
    require(transfer(to, value), 'transfer failed');
    emit TransferData(msg.sender, to, data);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public virtual override returns (bool success) {
    require(to != address(0), 'to should not be null');
    require(value <= balances[from].balance, 'value should be less than balance');
    require(value <= allowed[from][msg.sender], 'value should be less than allowance');

    if (balances[to].firstTransaction == 0) {
      balances[to].firstTransaction = block.timestamp;
      tokenHolders.push(to);
    }

    balances[from].balance -= value;
    balances[to].balance += value;
    allowed[from][msg.sender] -= value;
    emit Transfer(from, to, value);
    return true;
  }

  function transferFromWithData(
    address from,
    address to,
    uint256 value,
    bytes memory data
  ) public virtual override returns (bool success) {
    require(transferFrom(from, to, value), 'transfer failed');
    emit TransferData(from, to, data);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public virtual override returns (bool) {
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev ApproveAndCall the passed address to spend the specified amount of tokens on behalf of msg.sender and call
   * the receiveApproval function on that contract. This allows users to use their tokens to interact with
   * contracts in one function call instead of two.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   * @param data Extra data to be sent along the call.
   */
  function approveAndCall(
    address spender,
    uint256 value,
    bytes memory data
  ) public returns (bool success) {
    require(approve(spender, value), 'Could not approve amount for spender');
    IApproveAndCallable(spender).receiveApproval(msg.sender, value, address(this), data);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner The address which owns the funds.
   * @param spender The address which will spend the funds.
   * @return remaining A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public view override returns (uint256 remaining) {
    return allowed[owner][spender];
  }

  /**
   * @dev approve should be called when allowed[spender] == 0. To increment
   * allowed value it's better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined).
   * From MonolithDAO ERC20Token.sol
   */
  function increaseApproval(address spender, uint256 addedValue) public override returns (bool success) {
    allowed[msg.sender][spender] += addedValue;
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseApproval(address spender, uint256 subtractedValue) public override returns (bool success) {
    uint256 oldValue = allowed[msg.sender][spender];
    if (subtractedValue > oldValue) {
      allowed[msg.sender][spender] = 0;
    } else {
      allowed[msg.sender][spender] = oldValue - subtractedValue;
    }
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param owner The address to query the the balance of.
   * @return balance An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address owner) public view override returns (uint256 balance) {
    return balances[owner].balance;
  }

  function setIpfsFieldContainerHash(string memory ipfsHash)
    public
    override
    authWithCustomReason(UPDATE_IPFSCONTAINERHASH_ROLE, 'Sender needs UPDATE_IPFSCONTAINERHASH_ROLE')
  {
    super.setIpfsFieldContainerHash(ipfsHash);
  }
}
