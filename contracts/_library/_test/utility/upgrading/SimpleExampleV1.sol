// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './SimpleIExample.sol';
import '../../../utility/upgrading/Upgradeable.sol';

/* Base version of Example class */
contract SimpleExampleV1 is SimpleIExample, Upgradeable {
  constructor(address _gateKeeper) Upgradeable(_gateKeeper) {}

  function getUint() public pure override returns (uint256) {
    return 10;
  }
}
