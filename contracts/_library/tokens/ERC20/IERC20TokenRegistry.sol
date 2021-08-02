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
import './IERC20Token.sol';

abstract contract IERC20TokenRegistry is Secured, Syncable {
  bytes32 public constant LIST_TOKEN_ROLE = 'LIST_TOKEN_ROLE';

  mapping(string => IERC20Token) public tokens;
  string[] public tokenIndex;

  constructor(address gateKeeper) Secured(gateKeeper) {}

  function addToken(string memory name, address token) public virtual;
}
