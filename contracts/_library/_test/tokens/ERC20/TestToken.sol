// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../../tokens/ERC20/ERC20Token.sol';

contract TestToken is ERC20Token {
  constructor(
    string memory name,
    uint8 decimals,
    address gateKeeper,
    string memory uiFieldDefinitionsHash
  ) ERC20Token(name, decimals, gateKeeper, uiFieldDefinitionsHash) {}

  function getDecimalsFor(
    bytes memory /*fieldName*/
  ) public view override returns (uint256) {
    return _decimals;
  }

  function getIndexLength() public view override returns (uint256 length) {
    length = tokenHolders.length;
  }

  function getByIndex(uint256 index) public view returns (address holder, uint256 balance) {
    holder = tokenHolders[index];
    balance = balances[tokenHolders[index]].balance;
  }

  function getByKey(address key) public view returns (address holder, uint256 balance) {
    holder = key;
    balance = balances[key].balance;
  }
}
