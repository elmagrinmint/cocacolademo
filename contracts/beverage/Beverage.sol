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
contract Beverage is Converter, StateMachine, IpfsFieldContainer, FileFieldContainer {
  bytes32 public constant STATE_DEMAND_FORECAST_APPROVED = 'DEMAND FORECAST APPROVED';
  bytes32 public constant STATE_RAW_MATERIALS_ORDERED = 'RAW MATERIALS ORDERED';
  bytes32 public constant STATE_AWAITING_MATERIALS = 'AWAITING MATERIALS';
  bytes32 public constant STATE_PRODUCTION_FINALISED = 'PRODUCTION FINALISED';
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
  string public _product; 
  string public _bottling;
  uint256 public _bottlingDate;
  uint256 public _co2ReceivedDate;
  uint256 public _concentrateReceivedDate;
  uint256 public _waterReceivedDate;
  uint256 public _shipmentDate;

  constructor(
    address gateKeeper,
    uint256 requestDate,
    string memory product,
    string memory bottling,
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
    string memory product,
    string memory bottling,
    uint256 bottlingDate,
    uint256 shipmentDate,
    uint256 co2ReceivedDate,
    uint256 concentrateReceivedDate,
    uint256 waterReceivedDate,
    string memory ipfsFieldContainerHash
  ) public {
    _requestDate = requestDate;
    _product = product;
    _bottling = bottling;
    _bottlingDate = bottlingDate;
    _co2ReceivedDate = co2ReceivedDate;
    _concentrateReceivedDate = concentrateReceivedDate;
    _waterReceivedDate = waterReceivedDate;
    _ipfsFieldContainerHash = ipfsFieldContainerHash;
  }

  function set_co2ReceivedDate(uint256 co2ReceivedDate) public{
     _co2ReceivedDate = co2ReceivedDate;
  }

  function get_co2ReceivedDate() public returns (uint256) {
    return _co2ReceivedDate;
  }

  function set_concentrateReceivedDate(uint256 concentrateReceivedDate) public{
     _concentrateReceivedDate = concentrateReceivedDate;
  }

  function get_concentrateReceivedDate() public returns (uint256) {
    return _concentrateReceivedDate;
  }
  
  function set_waterReceivedDate(uint256 waterReceivedDate) public{
     _waterReceivedDate = waterReceivedDate;
  }

  function get_waterReceivedDate() public returns (uint256) {
    return _waterReceivedDate;
  }


  /**
   * @notice Returns all the roles for this contract
   * @return bytes32[] array of raw bytes representing the roles
   */
  function getRoles() public view returns (bytes32[] memory) {
    return _roles;
  }

/*contract Beverage is Converter, StateMachine, IpfsFieldContainer, FileFieldContainer {
  bytes32 public constant STATE_DEMAND_FORECAST_APPROVED = 'DEMAND FORECAST APPROVED';
  bytes32 public constant STATE_RAW_MATERIALS_ORDERED = 'RAW MATERIALS ORDERED';
  bytes32 public constant STATE_AWAITING_MATERIALS = 'AWAITING MATERIALS';
  bytes32 public constant STATE_PRODUCTION_FINALISED = 'PRODUCTION FINALISED';
  bytes32 public constant STATE_COURIER_ASSIGNED = 'COURIER ASSIGNED';
  bytes32 public constant STATE_SHIPMENT_RECEIVED = 'SHIPMENT RECEIVED';
  bytes32 public constant STATE_SHIPMENT_REJECTED = 'SHIPMENT REJECTED';*/

  function setupStateMachine() internal override {
    //create all states
    createState(STATE_DEMAND_FORECAST_APPROVED);
    createState(STATE_RAW_MATERIALS_ORDERED);
    createState(STATE_AWAITING_MATERIALS);
    createState(STATE_PRODUCTION_FINALISED);
    createState(STATE_COURIER_ASSIGNED);
    createState(STATE_SHIPMENT_RECEIVED);
    createState(STATE_SHIPMENT_REJECTED);

    // add properties
    // STATE_DEMAND_FORECAST_APPROVED
    addNextStateForState(STATE_DEMAND_FORECAST_APPROVED, STATE_RAW_MATERIALS_ORDERED);
    addRoleForState(STATE_DEMAND_FORECAST_APPROVED, ROLE_ADMIN);

    // STATE_RAW_MATERIALS_ORDERED
    addNextStateForState(STATE_RAW_MATERIALS_ORDERED, STATE_AWAITING_MATERIALS);
    addRoleForState(STATE_RAW_MATERIALS_ORDERED, ROLE_ADMIN);
    addRoleForState(STATE_RAW_MATERIALS_ORDERED, ROLE_SUPPLIER);


    // STATE_AWAITING_MATERIALS
    addNextStateForState(STATE_AWAITING_MATERIALS, STATE_AWAITING_MATERIALS);
    addNextStateForState(STATE_AWAITING_MATERIALS, STATE_PRODUCTION_FINALISED);
    addRoleForState(STATE_AWAITING_MATERIALS, ROLE_ADMIN);
    //if(abi.encodePacked(this.get_co2ReceivedDate()).length == 0){
    addAllowedFunctionForState(STATE_AWAITING_MATERIALS, this.set_co2ReceivedDate.selector);
    //}
   //     if(this.get_concentrateReceivedDate() ==  0){
    addAllowedFunctionForState(STATE_AWAITING_MATERIALS, this.set_concentrateReceivedDate.selector);
   //     }
        //if(this.get_waterReceivedDate() ==  0){
    addAllowedFunctionForState(STATE_AWAITING_MATERIALS, this.set_waterReceivedDate.selector);
    //    }

    //STATE_PRODUCTION_FINALISED
    addNextStateForState(STATE_PRODUCTION_FINALISED, STATE_COURIER_ASSIGNED);
    addRoleForState(STATE_PRODUCTION_FINALISED, ROLE_ADMIN);


    // STATE_COURIER_ASSIGNED
    addNextStateForState(STATE_COURIER_ASSIGNED,STATE_SHIPMENT_RECEIVED);
    addNextStateForState(STATE_COURIER_ASSIGNED,STATE_SHIPMENT_REJECTED);
    addRoleForState(STATE_COURIER_ASSIGNED, ROLE_ADMIN);
    addRoleForState(STATE_COURIER_ASSIGNED, ROLE_RESELLER);

    setInitialState(STATE_DEMAND_FORECAST_APPROVED);
  }
}
