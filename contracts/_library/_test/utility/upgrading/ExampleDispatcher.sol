// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../../utility/upgrading/Dispatcher.sol';
import './ExampleStorage.sol';

/* Dispatcher for Example contracts */
contract ExampleDispatcher is ExampleStorage, Dispatcher {
  constructor(address _gateKeeper) Dispatcher(_gateKeeper) {}
}
