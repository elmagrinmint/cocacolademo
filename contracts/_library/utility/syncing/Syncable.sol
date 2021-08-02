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

/**
 * @title The listable item should also implement
 */
abstract contract Syncable {
  function getIndexLength() public view virtual returns (uint256 length);

  // Waiting for the time we can return structs from functions!
  // function getByIndex(uint index) constant public returns (address key, bool hasRole){
  // function getByKey(address _key) constant public returns (address key, bool hasRole){

  // Since ABIEncoderV2 we can now return the entire registry as address list in one call
  // function getIndex() constant public returns (address[] index) {

  // Since ABIEncoderV2 we can now return the entire registry as an array of structs in one call
  // function getContents() constant public returns (Struct[] memory items) {
}
