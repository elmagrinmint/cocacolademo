/**
 * Copyright (C) SettleMint NV - All Rights Reserved
 *
 * Use of this file is strictly prohibited without an active license agreement.
 * Distribution of this file, via any medium, is strictly prohibited.
 *
 * For license inquiries, contact hello@settlemint.com
 *
 * SPDX-License-Identifier: UNLICENSED
 */

pragma solidity ^0.8.0;

/**
 * @title RoleRegistry
 * @dev The RoleRegistry contract defines the methods and data structures to
 * record if addresses have certain roles or not.
 */
abstract contract IRoleRegistry {
  event Designated(address _address);
  event Discharged(address _address);
  event RoleRegistryCreated(address _address);

  /**
   * @dev Checks if an address has a certain role
   * @param _address The address to check for the role.
   * @return hasTheRole A boolean that is True if the address has the role.
   */
  function hasRole(address _address) public view virtual returns (bool hasTheRole);

  /**
   * @dev Gives the role to an address
   * @param _address The address to designate the role to.
   */
  function designate(address _address) public virtual;

  /**
   * @dev Removes the role from an address
   * @param _address The address to discharge fromn the role.
   */
  function discharge(address _address) public virtual;
}
