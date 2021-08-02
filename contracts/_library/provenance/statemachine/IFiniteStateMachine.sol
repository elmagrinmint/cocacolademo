// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Finite State Machine interface
 */
abstract contract IFiniteStateMachine {
  bytes32 public constant FINITE_STATE_MACHINE = 'FINITE_STATE_MACHINE';

  event StateTransition(uint256 index, address sender, bytes32 fromState, bytes32 toState);

  function initialState() public pure virtual returns (bytes32);

  function allStates() public view virtual returns (bytes32[] memory);

  function allRoles() public view virtual returns (bytes32[] memory);

  // Finite State Machines are described by a set of functions,
  // opposed to the legacy struct definitions you'll find in StateMachine.sol
  // This in an attempt to reduce the byte size of our deployed contracts
  function getNextStatesForState(bytes32 state) public view virtual returns (bytes32[] memory);

  function getAllowedRolesForState(bytes32 state) public view virtual returns (bytes32[] memory);

  function getAllowedFunctionsForState(bytes32 state) public view virtual returns (bytes4[] memory);

  function getPreconditionsForState(bytes32 state) public view virtual returns (bytes4[] memory);

  function getCallbacksForState(bytes32 state) public view virtual returns (bytes4[] memory);

  function getPreFunctionForState(bytes32 state) public pure virtual returns (bytes4);

  // Note that the FSM definitions all return bytes4 method signatures when it defines a list of functions
  // however for preconditions and callbacks we do need function pointers so define those separately as internal functions
  function getPreconditionFunctionsForState(bytes32 state)
    internal
    view
    virtual
    returns (function(uint256, bytes32, bytes32) internal view[] memory);

  function getCallbackFunctionsForState(bytes32 state)
    internal
    virtual
    returns (function(uint256, bytes32, bytes32) internal[] memory);
}
