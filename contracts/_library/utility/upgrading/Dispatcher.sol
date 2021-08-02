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

import './Upgradeable.sol';

/**
 * Found at: https://gist.github.com/Arachnid/4ca9da48d51e23e5cfe0f0e14dd6318f and
 * https://github.com/maraoz/solidity-proxy/blob/master/contracts/Dispatcher.sol
 *
 * The dispatcher is a minimal 'shim' that dispatches calls to a targeted
 * contract. Calls are made using 'delegatecall', meaning all storage and value
 * is kept on the dispatcher. As a result, when the target is updated, the new
 * contract inherits all the stored data and value from the old contract.
 */

contract Dispatcher is Upgradeable {
  constructor(address gateKeeper) Upgradeable(gateKeeper) {}

  fallback() external {
    bytes4 sig;
    assembly {
      sig := calldataload(0)
    }
    address dest = _target;

    assembly {
      calldatacopy(0x0, 0x0, calldatasize())
      let callResult := delegatecall(sub(gas(), 10000), dest, 0x0, calldatasize(), 0, 0)
      let retSz := returndatasize()
      returndatacopy(0, 0, retSz)
      return(0, retSz)
    }
  }

  function setTarget(address target) public {
    replace(target);
  }
}
