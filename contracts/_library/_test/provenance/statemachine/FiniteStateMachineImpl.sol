// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../../provenance/statemachine/FiniteStateMachine.sol';

contract FiniteStateMachineImpl is FiniteStateMachine {
  bytes32 public constant STATE_CREATED = 'STATE_CREATED';

  bytes32[] public _allStates = [STATE_CREATED];
  bytes32[] public _allRoles;

  StateMachineMeta[] internal _meta;

  struct StateMachineMeta {
    uint256 index;
    uint256 amount;
    string proof;
    string ipfsFieldContainerHash;
  }

  constructor(address gateKeeper) Secured(gateKeeper) {}

  function initialState() public pure override returns (bytes32) {
    return STATE_CREATED;
  }

  function allStates() public view override returns (bytes32[] memory) {
    return _allStates;
  }

  function allRoles() public view override returns (bytes32[] memory) {
    return _allRoles;
  }

  function getNextStatesForState(bytes32 state) public view override returns (bytes32[] memory) {}

  function getAllowedRolesForState(bytes32 state) public view override returns (bytes32[] memory) {}

  function getAllowedFunctionsForState(bytes32 state) public view override returns (bytes4[] memory) {}

  function getPreconditionsForState(bytes32 state) public view override returns (bytes4[] memory) {}

  function getCallbacksForState(bytes32 state) public view override returns (bytes4[] memory) {}

  function getCallbackFunctionsForState(bytes32 state)
    internal
    override
    returns (function(uint256, bytes32, bytes32) internal[] memory)
  {}

  function getPreFunctionForState(bytes32 state) public pure override returns (bytes4) {}

  function getPreconditionFunctionsForState(bytes32 state)
    internal
    view
    override
    returns (function(uint256, bytes32, bytes32) internal view[] memory)
  {}

  function preconditionsForState(bytes32 state)
    internal
    view
    returns (function(uint256, bytes32, bytes32) internal view[] memory)
  {}

  function callbacksForState(bytes32 state) internal returns (function(uint256, bytes32, bytes32) internal[] memory) {}

  function create(
    uint256 amount,
    string memory proof,
    string memory ipfsFieldContainerHash
  ) public {
    _registry.push();
    StateMachine storage sm = _registry[_registry.length - 1];
    sm.currentState = initialState();
    sm.createdAt = block.timestamp;
    sm.index = _registry.length - 1;

    _meta.push();
    StateMachineMeta storage meta = _meta[_meta.length - 1];
    meta.amount = amount;
    meta.proof = proof;
    meta.ipfsFieldContainerHash = ipfsFieldContainerHash;
    meta.index = _meta.length - 1;
  }

  function getByIndex(uint256 index) public view returns (StateMachine memory item, StateMachineMeta memory meta) {
    item = _registry[index];
    meta = _meta[index];
  }

  function getContents() public view returns (StateMachine[] memory registry, StateMachineMeta[] memory meta) {
    registry = _registry;
    meta = _meta;
  }
}
