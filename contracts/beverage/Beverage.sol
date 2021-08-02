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

import '../_library//authentication/Secured.sol';
import '../_library//provenance/statemachine/StateMachine.sol';
import '../_library//utility/metadata/IpfsFieldContainer.sol';
import '../_library//utility/metadata/FileFieldContainer.sol';
import '../_library//utility/conversions/Converter.sol';

/**
 * Beverage
 *
 * A beverage package exists of
 *  - a description of the generic state machine
 *
 * @title Beverage State machine implementation
 */
contract Generic is Converter, StateMachine, IpfsFieldContainer, FileFieldContainer {
  bytes32 public constant STATE_PURCHASE_REQUEST_RECEIVED = 'PURCHASE REQUEST RECEIVED';
  bytes32 public constant STATE_SUPPLIER_CHOSEN = 'SUPPLIER CHOSEN';
  bytes32 public constant STATE_COURIER_ASSIGNED = 'COURIER ASSIGNED';
  bytes32 public constant STATE_SHIPMENT_RECEIVED = 'SHIPMENT RECEIVED';
  bytes32 public constant STATE_SHIPMENT_REJECTED = 'SHIPMENT REJECTED';

  bytes32 public constant ROLE_ADMIN = 'ROLE_ADMIN';
  bytes32 public constant ROLE_SUPPLIER = 'ROLE_SUPPLIER';
  bytes32 public constant ROLE_CARRIER = 'ROLE_CARRIER';
  bytes32 public constant ROLE_RESELLER = 'ROLE_RESELLER';

  bytes32[] public _roles = [ROLE_ADMIN, ROLE_SUPPLIER, ROLE_CARRIER, ROLE_RESELLER];

  string public _uiFieldDefinitionsHash;
  /*string private _param1;
  address _param2;
  uint256 private _param3;
   */
  uint256 public _requestDate;
  bytes32 public _product; 
  bytes32 public _bottling;
  uint256 public _bottlingDate; 

  uint256 public _shipmentDate;

  constructor(
    address gateKeeper,
    uint256 requestDate,
    bytes32 product,
    bytes32 bottling,
    uint256 bottlingDate,
    uint256 shipmentDate,
    string memory ipfsFieldContainerHash,
    string memory uiFieldDefinitionsHash
  ) Secured(gateKeeper) {
    _requestDate = requestDate;
    _product = product;
    _bottling = bottling;
    _bottlingDate = bottlingDate;
    _shipmentDate = shipmentDate;
    _ipfsFieldContainerHash = ipfsFieldContainerHash;
    _uiFieldDefinitionsHash = uiFieldDefinitionsHash;
    setupStateMachine();
  }

  /**
   * @notice Updates state machine properties
   * @param requestDate Update the Date when the Order was requested
   * @param product Update the product requested
   * @param bottling Update the bottling type
   * @param shipmentDate Update the shipment date
   * @param ipfsFieldContainerHash ipfs hash of vehicle metadata
   */
  function edit(
    uint256 requestDate,
    bytes32 product,
    bytes32 bottling,
    uint256 bottlingDate,
    uint256 shipmentDate,
    string memory ipfsFieldContainerHash
  ) public {
    _requestDate = requestDate;
    _product = product;
    _bottling = bottling;
    _bottlingDate = bottlingDate;
    _ipfsFieldContainerHash = ipfsFieldContainerHash;
  }

  /**
   * @notice Returns all the roles for this contract
   * @return bytes32[] array of raw bytes representing the roles
   */
  function getRoles() public view returns (bytes32[] memory) {
    return _roles;
  }


  function setupStateMachine() internal override {
    //create all states
    createState(STATE_PURCHASE_REQUEST_RECEIVED);
    createState(STATE_SUPPLIER_CHOSEN);
    createState(STATE_COURIER_ASSIGNED);
    createState(STATE_SHIPMENT_RECEIVED);
    createState(STATE_SHIPMENT_REJECTED);

    // add properties
    // STATE_ONE
    addNextStateForState(STATE_PURCHASE_REQUEST_RECEIVED, STATE_SUPPLIER_CHOSEN);
    addRoleForState(STATE_PURCHASE_REQUEST_RECEIVED, ROLE_ADMIN);

    // STATE_TWO
    addNextStateForState(STATE_SUPPLIER_CHOSEN, STATE_COURIER_ASSIGNED);
    addRoleForState(STATE_SUPPLIER_CHOSEN, ROLE_ADMIN);
    addRoleForState(STATE_COURIER_ASSIGNED, ROLE_SUPPLIER);


    // STATE_THREE
    addNextStateForState(STATE_COURIER_ASSIGNED, STATE_SHIPMENT_RECEIVED);
    addRoleForState(STATE_COURIER_ASSIGNED, ROLE_ADMIN);
    addRoleForState(STATE_COURIER_ASSIGNED, ROLE_RESELLER);

    // STATE_FOUR
    addNextStateForState(STATE_COURIER_ASSIGNED, STATE_SHIPMENT_REJECTED);

    setInitialState(STATE_PURCHASE_REQUEST_RECEIVED);
  }
}
