// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Migrations {
  address public owner;
  uint256 public lastCompletedMigration;

  constructor() {
    owner = msg.sender;
  }

  modifier restricted() {
    require(msg.sender == owner, 'the account sending this transaction is not the owner of this contract');
    _;
  }

  function setCompleted(uint256 completed) public restricted {
    lastCompletedMigration = completed;
  }

  function upgrade(address newAddress) public restricted {
    Migrations upgraded = Migrations(newAddress);
    upgraded.setCompleted(lastCompletedMigration);
  }
}
