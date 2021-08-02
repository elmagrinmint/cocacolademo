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

import '../../utility/syncing/Syncable.sol';
import '../../authentication/Secured.sol';
import '../../utility/metadata/IpfsFieldContainer.sol';

abstract contract IERC20Token is Secured, Syncable, IpfsFieldContainer {
  bytes32 public constant MINT_ROLE = 'MINT_ROLE';
  bytes32 public constant BURN_ROLE = 'BURN_ROLE';

  string public _name;
  uint8 public _decimals;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event TransferData(address indexed from, address indexed to, bytes data);
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(
    string memory name,
    uint8 decimals,
    address gateKeeper
  ) Secured(gateKeeper) {
    _name = name;
    _decimals = decimals;
  }

  function mint(address to, uint256 amount) public virtual returns (bool success);

  function mintToRoleRegistry(address roleRegistryAddress, uint256 amount) public virtual returns (bool success);

  function burn(address from, uint256 amount) public virtual returns (bool success);

  function burnFromRoleRegistry(address roleRegistryAddress, uint256 amount) public virtual returns (bool success);

  function transfer(address to, uint256 value) public virtual returns (bool success);

  function transferWithData(
    address to,
    uint256 value,
    bytes memory data
  ) public virtual returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public virtual returns (bool success);

  function transferFromWithData(
    address from,
    address to,
    uint256 value,
    bytes memory data
  ) public virtual returns (bool success);

  function approve(address spender, uint256 value) public virtual returns (bool);

  function allowance(address owner, address spender) public view virtual returns (uint256 remaining);

  function increaseApproval(address spender, uint256 addedValue) public virtual returns (bool success);

  function decreaseApproval(address spender, uint256 subtractedValue) public virtual returns (bool success);

  function balanceOf(address owner) public view virtual returns (uint256 balance);
}
