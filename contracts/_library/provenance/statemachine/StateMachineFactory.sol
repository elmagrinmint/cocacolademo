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
import '../../utility/ui/UIFieldDefinitions.sol';
import './StateMachine.sol';
import './StateMachineRegistry.sol';

/**
 * @title Base contract for state machine factories
 */
contract StateMachineFactory is UIFieldDefinitions, Secured {
  bytes32 public constant CREATE_STATEMACHINE_ROLE = 'CREATE_STATEMACHINE_ROLE';
  StateMachineRegistry internal _registry;

  event StateMachineCreated(address statemachine);

  constructor(GateKeeper gateKeeper, StateMachineRegistry registry) Secured(address(gateKeeper)) {
    _registry = registry;
  }

  /**
   * @notice Sets the value of `_uiFieldDefinitionsHash`
   * @param uiFieldDefinitionsHash value to assign to _uiFieldDefinitionsHash
   */
  function setUIFieldDefinitionsHash(string memory uiFieldDefinitionsHash)
    public
    override
    authWithCustomReason(UPDATE_UIFIELDDEFINITIONS_ROLE, 'Sender needs UPDATE_UIFIELDDEFINITIONS_ROLE')
  {
    _uiFieldDefinitionsHash = uiFieldDefinitionsHash;
  }

  /**
   * @notice Retrieves the value of `_uiFieldDefinitionsHash`
   */
  function getUIFieldDefinitionsHash() public view override returns (string memory) {
    return _uiFieldDefinitionsHash;
  }

  // Due to the fact that the param list is dependant on the statemachine implementation,
  // this cannot be an abstract contract but you still have to implement the create() function.
  // This is a good example. Make sure to emit the StateMachineCreated event.
  //
  // function create(
  //   uint256 amount,
  //   string memory proof,
  //   string memory ipfsFieldContainerHash
  // )
  //   public
  //   auth(CREATE_STATEMACHINE_ROLE)
  // {
  //   require(amount > 0, "The amount of an expense cannot be zero");
  //   bytes memory memProof = bytes(proof);
  //   require(memProof.length > 0, "A proof file is required for all expenses");
  //
  //   Expense expense = new Expense(
  //     gateKeeper,
  //     amount,
  //     proof,
  //     ipfsFieldContainerHash,
  //     _uiFieldDefinitionsHash,
  //     msg.sender
  //   );

  //   // Give every role registry a single permission on the newly created expense.
  //   bytes32[] memory roles = expense.getRoles();
  //   for (uint i = 0; i < roles.length; i++) {
  //     gateKeeper.createPermission(
  //       gateKeeper.getRoleRegistryAddress(roles[i]),
  //       address(expense),
  //       roles[i],
  //       address(this)
  //     );
  //   }

  //   _registry.insert(address(expense), msg.sender);
  //   emit StateMachineCreated(msg.sender,address(expense),amount);
  // }
}
