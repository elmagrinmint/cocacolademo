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
import './Upgradeable.sol';

contract UpgradeableRegistry is Upgradeable {
  bytes32 public constant UPGRADEABLE_REGISTRY = 'UPGRADEABLE_REGISTRY';

  address[] internal _registries;
  mapping(address => bool) internal _blacklisted;

  constructor(address gateKeeper) Upgradeable(gateKeeper) {}

  /**
   * Returns the current registry address
   */
  function current() public view returns (address) {
    return _target;
  }

  /**
   * Returns all non blacklisted registry addresses
   */
  function registries() public view returns (address[] memory) {
    uint8 counter = 0;
    address[] memory tmp = new address[](_registries.length);
    for (uint256 t = 0; t < _registries.length; t++) {
      if (!_blacklisted[_registries[t]]) {
        tmp[counter] = _registries[t];
        counter++;
      }
    }

    address[] memory nonBlacklistedRegistries = new address[](counter);
    for (uint256 c = 0; c < counter; c++) {
      nonBlacklistedRegistries[c] = tmp[c];
    }

    return nonBlacklistedRegistries;
  }

  /**
   * Returns all addresses (including the blacklisted addresses)
   */
  function allRegistries() public view returns (address[] memory) {
    return _registries;
  }

  /**
   * Upgrade the current target
   */
  function upgrade(address registry) public {
    require(_blacklisted[registry] == false, 'Can not upgrade to a previously blacklisted address');
    require(registry != _target, 'Registry already set');
    _registries.push(registry);
    replace(registry);
  }

  /**
   * Blacklist a registry address
   */
  function blacklist(address registry) public auth(UPGRADE_CONTRACT) {
    bool known = false;
    for (uint256 t = 0; t < _registries.length; t++) {
      if (_registries[t] == registry) {
        known = true;
        break;
      }
    }
    require(known == true, 'Unknown registry address');
    _blacklisted[registry] = true;
  }

  /**
   * Whitelist a registry address
   */
  function whitelist(address registry) public auth(UPGRADE_CONTRACT) {
    require(_blacklisted[registry] == true, 'Registry not blacklisted');
    _blacklisted[registry] = false;
  }
}
