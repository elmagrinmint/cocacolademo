// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './ExampleStorage.sol';
import './IExample.sol';
import '../../../utility/upgrading/Upgradeable.sol';

/* Base version of Example class */
contract ExampleV1 is ExampleStorage, IExample, Upgradeable {
  constructor(address _gateKeeper) Upgradeable(_gateKeeper) {}

  function getUint() public view override returns (uint256) {
    return _value;
  }

  function getValues() public view override returns (uint256 v1, uint256 v2) {
    v1 = _value;
    v2 = 2;
  }

  function setUint(uint256 value) public override {
    _value = value;
  }
}
