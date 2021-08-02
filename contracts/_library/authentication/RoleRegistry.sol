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

import './interfaces/IRoleRegistry.sol';
import './Secured.sol';
import '../utility/syncing/Syncable.sol';

/**
 * @title Base contract for role registries
 * @dev The RoleRegistry contract defines the methods and data structures to
 * record if addresses have certain roles or not.
 */
contract RoleRegistry is IRoleRegistry, Syncable, Secured {
  bytes32 public constant DESIGNATE_ROLE = bytes32('DESIGNATE_ROLE');

  struct RoleHolderContainer {
    bool roleDesignated;
    uint256 creationDate;
  }

  mapping(address => RoleHolderContainer) private roleHolders;
  address[] private roleHoldersIndex;

  constructor(address _gateKeeper) Secured(_gateKeeper) {
    emit RoleRegistryCreated(address(this));
  }

  /**
   * @notice Returns a list of all the holders of this role.
   * @dev Returns a list of all the holders of this role.
   * @return allRoleHolders array with all role holders' addresses
   */
  function getRoleHolders() public view returns (address[] memory allRoleHolders) {
    return roleHoldersIndex;
  }

  /**
   * @notice Checks if an address has this role
   * @dev Checks if `_address` has given the role managed by this role registry
   * @param _address The address to check for the role.
   * @return hasTheRole A boolean that is True if the address has the role.
   */
  function hasRole(address _address) public view override returns (bool hasTheRole) {
    hasTheRole = roleHolders[_address].roleDesignated;
  }

  /**
   * @notice Gives the role to an address
   * @dev Gives the role managed by this role registry to `_address`. Access is limited by the ACL.
   * @param _address The address to designate the role to.
   */
  function designate(address _address)
    public
    override
    authWithCustomReason(DESIGNATE_ROLE, 'Sender needs DESIGNATE_ROLE')
  {
    if (roleHolders[_address].creationDate == 0) {
      roleHoldersIndex.push(_address);
      roleHolders[_address].creationDate = block.timestamp;
    }
    roleHolders[_address].roleDesignated = true;
    emit Designated(_address);
  }

  /**
   * @notice Removes the role from an address
   * @dev Removes the role from `_address`. Access is limited by the ACL.
   * @param _address The address to discharge fromn the role.
   */
  function discharge(address _address)
    public
    override
    authWithCustomReason(DESIGNATE_ROLE, 'Sender needs DESIGNATE_ROLE')
  {
    require(roleHolders[_address].creationDate > 0, 'This address was never designated to this role');

    uint256 i = 0;
    while (roleHoldersIndex[i] != _address) {
      i++;
    }
    for (uint256 j = i; j < roleHoldersIndex.length - 1; j++) {
      roleHoldersIndex[j] = roleHoldersIndex[j + 1];
    }
    roleHoldersIndex.pop();

    roleHolders[_address].roleDesignated = false;
    emit Discharged(_address);
  }

  /**
   * @notice Returns the length of the index array
   * @dev Returns the length of the index array
   * @return length the amount of items in the index array
   */
  function getIndexLength() public view override returns (uint256 length) {
    length = roleHoldersIndex.length;
  }

  /**
   * @notice Returns the information for the key at a given index
   * @dev Returns the information for the key at index `_index`
   * @param _index The index of the key in the key array
   * @return key the information for the key on a certain index
   */
  function getByIndex(uint256 _index) public view returns (address key, bool hasTheRole) {
    key = roleHoldersIndex[_index];
    hasTheRole = roleHolders[roleHoldersIndex[_index]].roleDesignated;
  }

  /**
   * @notice Returns the information for the key
   * @dev Returns the information for the key `_key`
   * @param _key The key to get the info for
   * @return key the information for the key
   */
  function getByKey(address _key) public view returns (address key, bool hasTheRole) {
    key = _key;
    hasTheRole = roleHolders[_key].roleDesignated;
  }
}
