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

import '../../authentication/Secured.sol';
import './IERC20Token.sol';
import './IERC20TokenRegistry.sol';

contract IERC20TokenFactory is Secured {
  bytes32 public constant CREATE_TOKEN_ROLE = 'CREATE_TOKEN_ROLE';
  IERC20TokenRegistry internal _tokenRegistry;

  event TokenCreated(address _address, string _name);

  constructor(address tokenRegistry, address gateKeeper) Secured(gateKeeper) {
    _tokenRegistry = IERC20TokenRegistry(tokenRegistry);
  }
}
