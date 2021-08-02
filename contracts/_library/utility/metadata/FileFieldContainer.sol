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

contract FileFieldContainer {
  bytes32[] internal _fileKeys;
  mapping(bytes32 => bool) internal _knownFileKeys;
  mapping(bytes32 => string) internal _fileFieldsMap;

  function setContractFile(bytes32 key, string memory file) public {
    if (!_knownFileKeys[key]) {
      _fileKeys.push(key);
      _knownFileKeys[key] = true;
    }

    _fileFieldsMap[key] = file;
  }
}
