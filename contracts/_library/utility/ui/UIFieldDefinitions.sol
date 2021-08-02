// SPDX-License-Identifier: UNLICENSED
/**
 * Copyright (C) SettleMint NV - All Rights Reserved
 *
 * Use of this file is strictly prohibited without an active license agreement.
 * Distribution of this file, via any medium, is strictly prohibited.
 *
 * For license inquiries, contact hello@settlemint.com
 */

// solium-disable mixedcase
pragma solidity ^0.8.0;

abstract contract UIFieldDefinitions {
  bytes32 public constant UPDATE_UIFIELDDEFINITIONS_ROLE = 'UPDATE_UIFIELDDEFINITIONS_ROLE';
  string internal _uiFieldDefinitionsHash;

  function getUIFieldDefinitionsHash() public view virtual returns (string memory);

  function setUIFieldDefinitionsHash(string memory uiFieldDefinitionsHash) public virtual;
}
