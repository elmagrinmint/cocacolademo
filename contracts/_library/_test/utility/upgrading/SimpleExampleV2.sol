// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './SimpleIExample.sol';
import '../../../utility/upgrading/Upgradeable.sol';

/* The 'upgraded' version of ExampleV1 which modifies getUint to return 1 */
contract SimpleExampleV2 is SimpleIExample, Upgradeable {
  constructor(address _gateKeeper) Upgradeable(_gateKeeper) {}

  function getUint() public pure override returns (uint256) {
    return 1;
  }
}
