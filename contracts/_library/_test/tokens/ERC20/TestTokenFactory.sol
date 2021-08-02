// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../../tokens/ERC20/ERC20TokenFactory.sol';
import './TestToken.sol';
import './TestTokenRegistry.sol';

contract TestTokenFactory is ERC20TokenFactory {
  constructor(address registry, address gateKeeper) ERC20TokenFactory(registry, gateKeeper) {}

  function createToken(string memory name, uint8 decimals) public auth(CREATE_TOKEN_ROLE) {
    TestToken newToken = new TestToken(name, decimals, address(gateKeeper), _uiFieldDefinitionsHash);
    _tokenRegistry.addToken(name, address(newToken));
    emit TokenCreated(address(newToken), name);
    gateKeeper.createPermission(msg.sender, address(newToken), bytes32('MINT_ROLE'), msg.sender);
    gateKeeper.createPermission(msg.sender, address(newToken), bytes32('BURN_ROLE'), msg.sender);
  }
}
