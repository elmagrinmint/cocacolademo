// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './ExampleStorage.sol';
import './IExample.sol';
import '../../../utility/upgrading/Upgradeable.sol';

/* The 'upgraded' version of ExampleV1 which modifies getUint to return _value+10  */
contract ExampleV2 is ExampleStorage, IExample, Upgradeable {
  constructor(address _gateKeeper) Upgradeable(_gateKeeper) {}

  function getUint() public view override returns (uint256) {
    return _value + 10;
  }

  function getValues() public view override returns (uint256 v1, uint256 v2) {
    v1 = 100;
    v2 = _value;
  }

  function setUint(uint256 value) public override {
    _value = value;
  }
}
