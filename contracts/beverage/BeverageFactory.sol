/**
 * Copyright (C) SettleMint NV - All Rights Reserved
 *
 * Use of this file is strictly prohibited without an active license agreement.
 * Distribution of this file, via any medium, is strictly prohibited.
 *
 * For license inquiries, contact hello@settlemint.com
 *
 * SPDX-License-Identifier: UNLICENSED
 */

pragma solidity ^0.8.0;

import '../_library//provenance/statemachine/StateMachineFactory.sol';
import './Beverage.sol';
import './BeverageRegistry.sol';

/**
 * @title Factory contract for Beverage state machines
 */
contract BeverageFactory is StateMachineFactory {
  constructor(GateKeeper gateKeeper, BeverageRegistry registry) StateMachineFactory(gateKeeper, registry) {}

  /**
   * @notice Create new Beverage instance
   * @dev Factory method to create a new state machine. Emits StateMachineCreated event.
   * @param requestDate the first parameter of the state machine
   * @param product the second parameter of the state machine
   * @param bottling the third parameter of the state machine
   * @param bottlingDate the bottling date
   * @param shipmentDate the Shipment date
   * @param ipfsFieldContainerHash ipfs hash of vehicle metadata
   */
  function create(
  uint256  requestDate,
  string memory product,
  string memory  bottling,
  uint256  bottlingDate, 
  uint256  shipmentDate,
  string memory ipfsFieldContainerHash
  ) public authWithCustomReason(CREATE_STATEMACHINE_ROLE, 'Sender needs CREATE_STATEMACHINE_ROLE') {
    bytes memory memProof = bytes(product);
    require(memProof.length > 0, 'A Beverage name is required');

    Beverage beverage =
      new Beverage(address(gateKeeper), requestDate, product, bottling, bottlingDate, shipmentDate, ipfsFieldContainerHash, _uiFieldDefinitionsHash);
    // Give every role registry a single permission on the newly created expense.
    bytes32[] memory roles = beverage.getRoles();
    for (uint256 i = 0; i < 1; i++) {
      gateKeeper.createPermission(
        gateKeeper.getRoleRegistryAddress(roles[i]),
        address(beverage),
        roles[i],
        address(this)
      );
    }
    _registry.insert(address(beverage));
    emit StateMachineCreated(address(beverage));
  }
}
