// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../../tokens/ERC20/ERC20TokenRegistry.sol';

contract TestTokenRegistry is ERC20TokenRegistry {
  constructor(address gateKeeper) ERC20TokenRegistry(gateKeeper) {}
}
