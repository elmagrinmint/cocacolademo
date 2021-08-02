// SPDX-License-Identifier: UNLICENSED
/**
 * Copyright (C) SettleMint NV - All Rights Reserved
 *
 * Use of this file is strictly prohibited without an active license agreement.
 * Distribution of this file, via any medium, is strictly prohibited.
 *
 * For license inquiries, contcontact hello@settlemint.com
 */

pragma solidity ^0.8.0;

import '../../authentication/Secured.sol';

/**
 * @title Base contract for state machines
 */
abstract contract StateMachine is Secured {
  event Transition(address sender, bytes32 fromState, bytes32 toState);

  struct State {
    // a boolean to check if the state is actually created
    bool hasBeenCreated;
    // a mapping of functions that can be executed when in this state
    mapping(bytes4 => bool) allowedFunctions;
    // a list of all the roles that have been configured for this state
    bytes32[] allowedRoles;
    // a list of all the preconditions that have been configured for this state
    function(bytes32, bytes32) internal view[] preConditions;
    // a list of callbacks to execute before the state transition completes
    function(bytes32, bytes32) internal[] callbacks;
    // a list of states that can be transitioned to
    bytes32[] nextStates;
    // function that executes logic and then does a StateTransition
    bytes4 preFunction;
  }

  struct StateTransition {
    bytes32 fromState;
    bytes32 toState;
    address actor;
    uint256 timestamp;
  }

  StateTransition[] public history;

  mapping(bytes32 => State) internal states;
  bytes32[] internal possibleStates;
  bytes32 internal currentState;

  // a list of selectors that might be allowed functions
  bytes4[] internal knownSelectors;
  mapping(bytes4 => bool) internal knownSelector;

  /**
   * @notice Modifier to ensure the statemachine was setup
   */
  modifier checkStateMachineSetup {
    require(possibleStates.length > 0, 'this statemachine has not been setup yet');
    _;
  }

  /**
   * @notice Modifier to secure functions for a specific state
   */
  modifier checkAllowedFunction {
    require(states[currentState].allowedFunctions[msg.sig], 'this function is not allowed in this state');
    _;
  }

  /**
   * @notice Modifier that checks if we can trigger a transition between the current state and the next state
   */
  modifier checkTransitionCriteria(bytes32 toState) {
    checkAllTransitionCriteria(getCurrentState(), toState);
    _;
  }

  modifier doesStateExist(bytes32 state) {
    require(states[state].hasBeenCreated, 'the state has not been created yet');
    _;
  }

  /**
   * @notice Returns the length of the history
   */
  function getHistoryLength() public view returns (uint256) {
    return history.length;
  }

  /**
   * @notice Returns history as tuple for given index.
   * @dev Requires the index to be within the bounds of the history array
   */
  function getHistory(uint256 index)
    public
    view
    returns (
      bytes32 fromState,
      bytes32 toState,
      address actor,
      uint256 timestamp
    )
  {
    require(index >= 0 && index < history.length, 'Index out of bounds');
    return (history[index].fromState, history[index].toState, history[index].actor, history[index].timestamp);
  }

  /**
   * @notice Returns the name of the current state of this object.
   * @dev Requires the current state to be configured before calling this function
   */
  function getCurrentState() public view returns (bytes32 state) {
    require(states[currentState].hasBeenCreated, 'the initial state has not been created yet');
    return currentState;
  }

  /**
   * @notice Returns a list of all the possible states of this object.
   */
  function getAllStates() public view returns (bytes32[] memory allStates) {
    return possibleStates;
  }

  /**
   * @notice Returns a list of all the possible next states of the current state.
   */
  function getNextStates() public view returns (bytes32[] memory nextStates) {
    return states[currentState].nextStates;
  }

  /**
   * @notice Returns state as tuple for give state.
   */
  function getState(bytes32 state)
    public
    view
    returns (
      bytes32 name,
      bytes32[] memory nextStates,
      bytes32[] memory allowedRoles,
      bytes4[] memory allowedFunctions,
      bytes4 preFunction
    )
  {
    State storage s = states[state]; // copy to memory

    uint8 counter = 0;
    bytes4[] memory tmp = new bytes4[](knownSelectors.length);
    for (uint256 i = 0; i < knownSelectors.length; i++) {
      if (states[state].allowedFunctions[knownSelectors[i]]) {
        tmp[counter] = knownSelectors[i];
        counter += 1;
      }
    }

    bytes4[] memory selectors = new bytes4[](counter);
    for (uint256 j = 0; j < counter; j++) {
      selectors[j] = tmp[j];
    }

    return (state, s.nextStates, s.allowedRoles, selectors, s.preFunction);
  }

  /**
   * @notice Transitions the state and executes all callbacks.
   * @dev Emits a Transition event after a successful transition.
   */
  function transitionState(bytes32 toState) public checkStateMachineSetup() checkTransitionCriteria(toState) {
    bytes32 oldState = currentState;
    currentState = toState;

    function(bytes32, bytes32) internal[] storage callbacks = states[toState].callbacks;
    for (uint256 i = 0; i < callbacks.length; i++) {
      callbacks[i](oldState, toState);
    }

    history.push(
      StateTransition({ fromState: oldState, toState: toState, actor: msg.sender, timestamp: block.timestamp })
    );

    emit Transition(msg.sender, oldState, currentState);
  }

  /**
   * @dev Abstract function to setup te state machine configuration
   */
  function setupStateMachine() internal virtual;

  function createState(bytes32 stateName) internal {
    require(!states[stateName].hasBeenCreated, 'this state has already been created');
    states[stateName].hasBeenCreated = true;
    possibleStates.push(stateName);
  }

  function addRoleForState(bytes32 state, bytes32 role) internal doesStateExist(state) {
    states[state].allowedRoles.push(role);
  }

  function addAllowedFunctionForState(bytes32 state, bytes4 allowedFunction) internal doesStateExist(state) {
    if (!knownSelector[allowedFunction]) {
      knownSelector[allowedFunction] = true;
      knownSelectors.push(allowedFunction);
    }
    states[state].allowedFunctions[allowedFunction] = true;
  }

  function addNextStateForState(bytes32 state, bytes32 nextState)
    internal
    doesStateExist(state)
    doesStateExist(nextState)
  {
    states[state].nextStates.push(nextState);
  }

  function addCallbackForState(bytes32 state, function(bytes32, bytes32) internal callback)
    internal
    doesStateExist(state)
  {
    states[state].callbacks.push(callback);
  }

  function addPreConditionForState(bytes32 state, function(bytes32, bytes32) internal view preCondition)
    internal
    doesStateExist(state)
  {
    states[state].preConditions.push(preCondition);
  }

  function setPreFunctionForState(bytes32 state, bytes4 functionSig) internal doesStateExist(state) {
    states[state].preFunction = functionSig;
  }

  /**
   * @notice Configures the initial state of an object
   */
  function setInitialState(bytes32 initialState) internal {
    require(states[initialState].hasBeenCreated, 'the initial state has not been created yet');
    require(
      currentState == 0,
      'the current state has already been set, so you cannot configure the initial state and override it'
    );
    currentState = initialState;
  }

  /**
   * @notice Function that checks if we can trigger a transition between two states
   * @dev This checks if the states exist, if the user has a role to go to the chosen next state and
   * @dev and if all the preconditions give the ok.
   */
  function checkAllTransitionCriteria(bytes32 fromState, bytes32 toState) private view {
    require(states[fromState].hasBeenCreated, 'the from state has not been configured in this object');
    require(states[toState].hasBeenCreated, 'the to state has not been configured in this object');
    require(
      checkNextStates(fromState, toState),
      'the requested next state is not an allowed next state for this transition'
    );
    require(
      checkAllowedRoles(toState),
      'the sender of this transaction does not have a role that allows transition between the from and to states'
    );
    checkPreConditions(fromState, toState);
  }

  /**
   * @notice Checks if it is allowed to transition between the given states
   */
  function checkNextStates(bytes32 fromState, bytes32 toState) private view returns (bool hasNextState) {
    hasNextState = false;
    bytes32[] storage nextStates = states[fromState].nextStates;
    for (uint256 i = 0; i < nextStates.length; i++) {
      if (keccak256(abi.encodePacked(nextStates[i])) == keccak256(abi.encodePacked(toState))) {
        hasNextState = true;
        break;
      }
    }
  }

  /**
   * @notice Checks all the custom preconditions that determine if it is allowed to transition to a next state
   * @dev Make sure the preconditions require or assert their checks and have an understandable error message
   */
  function checkPreConditions(bytes32 fromState, bytes32 toState) private view {
    function(bytes32, bytes32) internal view[] storage preConditions = states[toState].preConditions;
    for (uint256 i = 0; i < preConditions.length; i++) {
      preConditions[i](fromState, toState);
    }
  }

  /**
   * @notice Checks if the sender has a role that is allowed to transition to a next state
   */
  function checkAllowedRoles(bytes32 toState) private view returns (bool isAllowed) {
    isAllowed = false;
    bytes32[] storage allowedRoles = states[toState].allowedRoles;
    if (allowedRoles.length == 0) {
      isAllowed = true;
    }
    for (uint256 i = 0; i < allowedRoles.length; i++) {
      if (canPerform(msg.sender, allowedRoles[i])) {
        isAllowed = true;
        break;
      }
    }
  }
}
