// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../../tokens/IApproveAndCallable.sol';
import './TestToken.sol';

contract TestApproveAndCallable is IApproveAndCallable {
  function receiveApproval(
    address from,
    uint256 amount,
    address token,
    bytes memory data
  ) public override {
    emit ReceivedApproval(from, amount, token, data);

    assert(from != address(0x0));
    assert(token != address(0x0));
    assert(amount > 0);

    require(
      TestToken(token).allowance(from, address(this)) >= amount,
      'The allowance is less than the amount asking to be approved'
    );
    TestToken(token).transferFrom(from, address(this), amount);
  }
}
