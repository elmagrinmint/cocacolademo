// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../../provenance/statemachine/StateMachine.sol';

contract StateMachineImplHappy is StateMachine {
  bytes32 public constant STATE_CREATED = 'CREATED';
  bytes32 public constant STATE_TEMPORARY = 'TEMPORARY';
  bytes32 public constant STATE_MODIFIED = 'MODIFIED';
  bytes32 public constant STATE_ACCEPTED = 'ACCEPTED';
  bytes32 public constant STATE_REJECTED = 'REJECTED';
  bytes32 public constant STATE_ENDED = 'ENDED';

  bytes32 public constant ROLE_EDITOR = 'EDITOR';
  bytes32 public constant ROLE_COUNTERPARTY = 'COUNTERPARTY';

  bool public modified = false;
  bool public modificationTransitionHandled = false;

  address party1;
  address party2;
  mapping(address => bool) signatures;

  constructor(
    address gateKeeper,
    address partyOne,
    address partyTwo
  ) Secured(gateKeeper) {
    party1 = partyOne;
    party2 = partyTwo;
    setupStateMachine();
  }

  function modify() public checkAllowedFunction {
    modified = true;
  }

  function sign() public {
    signatures[msg.sender] = true;
  }

  function setupStateMachine() internal override {
    createState(STATE_CREATED);
    createState(STATE_MODIFIED);
    createState(STATE_ACCEPTED);
    createState(STATE_REJECTED);
    createState(STATE_TEMPORARY);
    createState(STATE_ENDED);

    // STATE_ENDED
    addRoleForState(STATE_ENDED, ROLE_EDITOR);

    // STATE_REJECTED
    addRoleForState(STATE_REJECTED, ROLE_COUNTERPARTY);

    // STATE_ACCEPTED
    addRoleForState(STATE_ACCEPTED, ROLE_COUNTERPARTY);
    addPreConditionForState(STATE_ACCEPTED, acceptPreCondition);
    addNextStateForState(STATE_ACCEPTED, STATE_ENDED);
    addNextStateForState(STATE_ACCEPTED, STATE_TEMPORARY);

    // STATE_MODIFIED
    addRoleForState(STATE_MODIFIED, ROLE_EDITOR);
    addAllowedFunctionForState(STATE_MODIFIED, this.modify.selector);
    addNextStateForState(STATE_MODIFIED, STATE_MODIFIED);
    addCallbackForState(STATE_MODIFIED, handleModificationTransition);
    addNextStateForState(STATE_MODIFIED, STATE_ACCEPTED);
    addNextStateForState(STATE_MODIFIED, STATE_REJECTED);

    // Adjust STATE_REJECTED
    addNextStateForState(STATE_REJECTED, STATE_MODIFIED);

    // STATE_CREATED
    addRoleForState(STATE_CREATED, ROLE_EDITOR);
    addAllowedFunctionForState(STATE_CREATED, this.modify.selector);
    addNextStateForState(STATE_CREATED, STATE_MODIFIED);
    addNextStateForState(STATE_CREATED, STATE_ACCEPTED);
    addNextStateForState(STATE_CREATED, STATE_REJECTED);
    addNextStateForState(STATE_TEMPORARY, STATE_ENDED);
    addCallbackForState(STATE_TEMPORARY, testInternalTransition);

    setInitialState(STATE_CREATED);
  }

  function handleModificationTransition(
    bytes32, /*fromState*/
    bytes32 /*toState*/
  ) internal {
    modificationTransitionHandled = true;
  }

  function acceptPreCondition(
    bytes32, /*fromState*/
    bytes32 /*toState*/
  ) internal view {
    require(signatures[party1], 'Party 1 did not sign yet');
    require(signatures[party2], 'Party 2 did not sign yet');
  }

  function testInternalTransition(
    bytes32, /*fromState*/
    bytes32 /*toState*/
  ) internal {
    transitionState(STATE_ENDED);
  }
}
