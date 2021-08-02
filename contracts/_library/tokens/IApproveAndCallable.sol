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

abstract contract IApproveAndCallable {
  event ReceivedApproval(address from, uint256 amount, address token, bytes _data);

  function receiveApproval(
    address _from,
    uint256 _amount,
    address _token,
    bytes memory _data
  ) public virtual;
}
