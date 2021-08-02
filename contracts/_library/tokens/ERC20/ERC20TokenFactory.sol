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
import './IERC20TokenRegistry.sol';
import './IERC20TokenFactory.sol';
import '../../utility/ui/UIFieldDefinitions.sol';

abstract contract ERC20TokenFactory is UIFieldDefinitions, IERC20TokenFactory {
  constructor(address registry, address gateKeeper) IERC20TokenFactory(registry, gateKeeper) {}

  // NOT IMPLEMENTED IN HERE BECAUSE THE IMPLEMENTATION IS OFTEN DIFFERENT
  // function createToken(string memory name, uint8 decimals) public virtual;

  function setUIFieldDefinitionsHash(string memory uiFieldDefinitionsHash)
    public
    override
    authWithCustomReason(UPDATE_UIFIELDDEFINITIONS_ROLE, 'Sender needs UPDATE_UIFIELDDEFINITIONS_ROLE')
  {
    _uiFieldDefinitionsHash = uiFieldDefinitionsHash;
  }

  function getUIFieldDefinitionsHash() public view override returns (string memory) {
    return _uiFieldDefinitionsHash;
  }
}
