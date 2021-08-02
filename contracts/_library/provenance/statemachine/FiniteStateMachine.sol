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
import '../../utility/syncing/Syncable.sol';
import './IFiniteStateMachine.sol';

/**
 * @title Base contract for state machines
 */
abstract contract FiniteStateMachine is IFiniteStateMachine, Secured, Syncable {
  StateMachine[] internal _registry;

  /**
   * @dev Struct defining a State Machine
   * @notice Gets decorated with StateMachineMeta
   */
  struct StateMachine {
    uint256 index;
    bytes32 currentState;
    Transition[] transitions;
    uint256 createdAt;
  }

  /**
   * @dev Struct defining a transition between states
   */
  struct Transition {
    bytes32 fromState;
    bytes32 toState;
    address actor;
    uint256 timestamp;
  }

  /**
   * @notice Returns the length of the state machine registry
   * @dev Returns the length of the state machine registry
   * @return length the number of state machines in the registry
   */
  function getIndexLength() public view override returns (uint256 length) {
    length = _registry.length;
  }

  // Due to a possibly different return type (include meta) this gets implemented in the inheriting contract
  // function getByIndex(uint index) public view returns (StateMachine memory item) {
  //   item = _registry[index];
  // }

  // Due to a possibly different return type (include meta) this gets implemented in the inheriting contract
  // function getContents() public view returns (StateMachine[] memory registry) {
  //   registry = _registry;
  // }

  function getCallbackFunctionsForState(bytes32 state)
    internal
    virtual
    override
    returns (function(uint256, bytes32, bytes32) internal[] memory);

  /**
   * @notice Transitions a state machine to a new state
   * @dev Ensures predefined transition criteria are met before transitioning to a new state.
   * Executes callbacks. Emits a Transition event after a successful transition.
   * @param fsmIndex registry index of the transitioning state machine
   * @param toState identifier of the state to transition to
   */
  function transitionState(uint256 fsmIndex, bytes32 toState) public checkTransitionCriteria(fsmIndex, toState) {
    StateMachine storage stateMachine = _registry[fsmIndex];
    bytes32 oldState = stateMachine.currentState;
    stateMachine.currentState = toState;

    function(uint256, bytes32, bytes32) internal[] memory callbacks = getCallbackFunctionsForState(toState);
    for (uint256 i = 0; i < callbacks.length; i++) {
      callbacks[i](fsmIndex, oldState, toState);
    }

    _registry[fsmIndex].transitions.push(
      Transition({ fromState: oldState, toState: toState, actor: msg.sender, timestamp: block.timestamp })
    );

    emit StateTransition(fsmIndex, msg.sender, oldState, toState);
  }

  function getNextStatesForState(bytes32 state) public view virtual override returns (bytes32[] memory);

  /**
   * @notice Checks whether it's possible to transition to the given state
   * @param fromState identifier of the state from which is being transitioned
   * @param toState identifier of the state to which is being transitioned to
   */
  function checkNextStates(bytes32 fromState, bytes32 toState) internal view returns (bool hasNextState) {
    bytes32[] memory nextStates = getNextStatesForState(fromState);

    hasNextState = false;
    for (uint256 i = 0; i < nextStates.length; i++) {
      if (keccak256(abi.encodePacked(nextStates[i])) == keccak256(abi.encodePacked(toState))) {
        hasNextState = true;
        break;
      }
    }
  }

  function getPreconditionFunctionsForState(bytes32 state)
    internal
    view
    virtual
    override
    returns (function(uint256, bytes32, bytes32) internal view[] memory);

  /**
   * @notice Checks all the custom preconditions that determine if it is allowed to transition to a next state
   * @dev Make sure the preconditions require or assert their checks and have an understandable error message
   * @param index registry index of the transitioning state machine
   * @param fromState identifier of the state from which is being transitioned
   * @param toState identifier of the state to which is being transitioned to
   */
  function checkPreConditions(
    uint256 index,
    bytes32 fromState,
    bytes32 toState
  ) private view {
    function(uint256, bytes32, bytes32) internal view[] memory preConditions =
      getPreconditionFunctionsForState(toState);

    for (uint256 i = 0; i < preConditions.length; i++) {
      preConditions[i](index, fromState, toState);
    }
  }

  function getAllowedRolesForState(bytes32 state) public view virtual override returns (bytes32[] memory);

  /**
   * @notice Checks if the sender has a role that is allowed to transition to a next state
   * @param toState identifier of the state to which is being transitioned to
   */
  function checkAllowedRoles(bytes32 toState) private view returns (bool isAllowed) {
    bytes32[] memory allowedRoles = getAllowedRolesForState(toState);

    isAllowed = false;
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

  function getAllowedFunctionsForState(bytes32 state) public view virtual override returns (bytes4[] memory);

  /**
   * @notice Modifier to secure functions for a specific state
   */
  modifier checkAllowedFunction(bytes32 state) {
    bytes4[] memory allowedFunctions = getAllowedFunctionsForState(state);

    bool isAllowed = false;
    for (uint256 i = 0; i < allowedFunctions.length; i++) {
      if (allowedFunctions[i] == msg.sig) {
        isAllowed = true;
        break;
      }
    }

    require(isAllowed, 'this function is not allowed in this state');
    _;
  }

  /**
   * @notice Modifier that checks if we can trigger a transition between the current state and the next state
   */
  modifier checkTransitionCriteria(uint256 index, bytes32 toState) {
    require(checkNextStates(_registry[index].currentState, toState), 'invalid to state');
    require(checkAllowedRoles(toState), 'transition to state not allowed');
    checkPreConditions(index, _registry[index].currentState, toState);
    _;
  }

  /**
   * @notice Modifier that checks if a state machine exists
   */
  modifier doesStateMachineExists(uint256 index) {
    require(_registry[index].createdAt > 0, 'state machine does not exist');
    _;
  }
}
