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

/**
 * Base contract that all upgradeable contracts should use
 *
 * Contracts implementing this interface are all called using delegatecall from
 * a dispatcher. As a result, _dest variables are shared with the
 * dispatcher contract, which allows the called contract to update these at will.
 *
 * _dest is the address of the contract currently implementing all the
 * functionality of the composite contract. Contracts should update this by
 * calling the internal function `replace`, which updates _dest.
 *
 * When upgrading a contract, restrictions on permissible changes to the set of
 * storage variables must be observed. New variables may be added, but existing
 * ones may not be deleted or replaced. Changing variable names is acceptable.
 * Structs in arrays may not be modified, but structs in maps can be, following
 * the same rules described above.
 */

contract Upgradeable is Secured {
  bytes32 public constant UPGRADE_CONTRACT = 'UPGRADE_CONTRACT';
  address public _target;

  event TargetChanged(address originalTarget, address newTarget);

  constructor(address gateKeeper) Secured(gateKeeper) {}

  /**
   * Performs a handover to a new implementing contract.
   */
  function replace(address target) internal auth(UPGRADE_CONTRACT) {
    emit TargetChanged(_target, target);
    _target = target;
  }
}
