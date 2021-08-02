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

contract IpfsFieldContainer {
  bytes32 public constant UPDATE_IPFSCONTAINERHASH_ROLE = 'UPDATE_IPFSCONTAINERHASH_ROLE';
  string public _ipfsFieldContainerHash;

  function getIpfsFieldContainerHash() public view virtual returns (string memory) {
    return _ipfsFieldContainerHash;
  }

  function setIpfsFieldContainerHash(string memory ipfsFieldContainerHash) public virtual {
    _ipfsFieldContainerHash = ipfsFieldContainerHash;
  }
}
