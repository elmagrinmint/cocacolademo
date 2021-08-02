// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/* Example contracts interface */
abstract contract IExample {
  function getUint() public view virtual returns (uint256);

  function getValues() public view virtual returns (uint256 v1, uint256 v2);

  function setUint(uint256 value) public virtual;
}
