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

import './IERC20TokenRegistry.sol';

contract ERC20TokenRegistry is IERC20TokenRegistry {
  event TokenAdded(address indexed token);

  constructor(address gateKeeper) IERC20TokenRegistry(gateKeeper) {}

  function addToken(string memory name, address token)
    public
    override
    authWithCustomReason(LIST_TOKEN_ROLE, 'Sender needs LIST_TOKEN_ROLE')
  {
    require(address(tokens[name]) == address(0x0), 'only accept unique names');
    tokens[name] = IERC20Token(token);
    tokenIndex.push(name);
    emit TokenAdded(token);
  }

  function getIndexLength() public view override returns (uint256 length) {
    length = tokenIndex.length;
  }

  function getByIndex(uint256 index) public view returns (string memory key, address contractAddress) {
    return getByKey(tokenIndex[index]);
  }

  function getByKey(string memory _key) public view returns (string memory key, address contractAddress) {
    contractAddress = address(tokens[_key]);
    key = _key;
  }
}
