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

/**
 * @title Manages contract permissions
 */
contract GateKeeper {
  bytes32 public constant CREATE_PERMISSIONS_ROLE = bytes32('CREATE_PERMISSIONS_ROLE');
  bytes32 public constant ADD_ROLEREGISTRY_ROLE = bytes32('ADD_ROLEREGISTRY_ROLE');
  bytes32 public constant ADD_KNOWNROLE_ROLE = bytes32('ADD_KNOWNROLE_ROLE');

  event SetPermission(address indexed entity, address indexed contractAddress, bytes32 indexed role, bool allowed);
  event ChangePermissionManager(address indexed contractAddress, bytes32 indexed role, address indexed manager);

  // whether a certain entity has a permission
  mapping(address => mapping(address => mapping(bytes32 => bool))) permissions;
  // who is the manager of a permission
  mapping(address => mapping(bytes32 => address)) permissionManager;
  // a mapping of roles to the address of their correspending role registry
  mapping(bytes32 => address) roleToRoleRegistry;

  // a list of all RoleRegistries
  IRoleRegistry[] roleRegistries;

  bytes32[] public knownRoles;
  mapping(bytes32 => bool) private knownRole;

  modifier onlyPermissionManager(address _contract, bytes32 role) {
    require(msg.sender == getPermissionManager(_contract, role), 'Sender is not the permission manager');
    _;
  }

  modifier auth(bytes32 _role) {
    require(hasPermission(msg.sender, address(this), _role), 'Sender does not have the correct permissions');
    _;
  }

  modifier authMany(bytes32[] memory _roles) {
    bool hasRole = false;
    for (uint256 i = 0; i < _roles.length; i++) {
      if (hasPermission(msg.sender, address(this), _roles[i])) {
        hasRole = true;
        break;
      }
    }
    require(hasRole == true, 'Sender does not have the correct permissions');
    _;
  }

  modifier authWithCustomReason(bytes32 _role, string memory reason) {
    require(hasPermission(msg.sender, address(this), _role), reason);
    _;
  }

  modifier authManyWithCustomReason(bytes32[] memory _roles, string memory reason) {
    bool hasRole = false;
    for (uint256 i = 0; i < _roles.length; i++) {
      if (hasPermission(msg.sender, address(this), _roles[i])) {
        hasRole = true;
        break;
      }
    }
    require(hasRole == true, reason);
    _;
  }

  constructor() {
    _createPermission(msg.sender, address(this), CREATE_PERMISSIONS_ROLE, msg.sender);
    _createPermission(msg.sender, address(this), ADD_ROLEREGISTRY_ROLE, msg.sender);
  }

  /**
   * @notice Adds an existing role registry to an internal collection.
   * @dev Adds an existing role registry to an internal collection. Access is limited by the ACL.
   * @param roleRegistry Address of the role registry to be included
   */
  function addRoleRegistry(address roleRegistry) external auth(ADD_ROLEREGISTRY_ROLE) {
    roleRegistries.push(IRoleRegistry(roleRegistry));
  }

  /**
   * @notice Creates a permission that wasn't previously set.
   * @dev Create a new permission granting `_entity` the ability to perform actions of role `_role` on `_contract` (setting `_manager` as parent).
   * If a created permission is removed it is possible to reset it with createPermission. Access is limited by the ACL.
   * @param _entity Address of the whitelisted entity that will be able to perform the role, this can be a user or a role registry
   * @param _contract Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
   * @param _role Identifier for the group of actions allowed to perform
   * @param _manager Entity address that will be able to grant and revoke the permission further.
   */
  function createPermission(
    address _entity,
    address _contract,
    bytes32 _role,
    address _manager
  ) public auth(CREATE_PERMISSIONS_ROLE) {
    if (!knownRole[_role]) {
      knownRoles.push(_role);
      knownRole[_role] = true;
    }

    _createPermission(_entity, _contract, _role, _manager);
  }

  /**
   * @notice Grants a permission if allowed.
   * @dev Grants `_entity` the ability to perform actions of role `_role` on `_contract`.
   * This requires `msg.sender` to be the permission manager.
   * @param _entity Address of the whitelisted entity that will be able to perform the role
   * @param _contract Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
   * @param _role Identifier for the group of actions allowed to perform
   */
  function grantPermission(
    address _entity,
    address _contract,
    bytes32 _role
  ) public onlyPermissionManager(_contract, _role) {
    _setPermission(_entity, _contract, _role, true);
  }

  /**
   * @notice Revokes permission if allowed.
   * @dev Revokes `_entity` the ability to perform actions of role `_role` on `_contract`.
   * This requires `msg.sender` to be the parent of the permission
   * @param _entity Address of the whitelisted entity that will be revoked access
   * @param _contract Address of the app in which the role is revoked
   * @param _role Identifier for the group of actions allowed to perform
   */
  function revokePermission(
    address _entity,
    address _contract,
    bytes32 _role
  ) public onlyPermissionManager(_contract, _role) {
    _setPermission(_entity, _contract, _role, false);
  }

  /**
   * @notice Sets the manager address of a permission on a contract
   * @dev Sets `_newManager` as the manager of the permission `_role` on `_contract`
   * This requires `msg.sender` to be the parent of the permission
   * @param _newManager Address for the new manager
   * @param _contract Address of the app in which the permission management is being transferred
   * @param _role Identifier for the group of actions allowed to perform
   */
  function setPermissionManager(
    address _newManager,
    address _contract,
    bytes32 _role
  ) public onlyPermissionManager(_contract, _role) {
    _setPermissionManager(_newManager, _contract, _role);
  }

  /**
   * @notice Get manager address for a permission on a contract
   * @dev Get manager address for the permission `_role` on `_contract`
   * @param _contract Contract address
   * @param _role Role identifier
   * @return Address of the manager for the permission
   */
  function getPermissionManager(address _contract, bytes32 _role) public view returns (address) {
    return permissionManager[_contract][_role];
  }

  /**
   * @notice Lists all the permissions of an entity on a contract address
   * @dev Lists all permissions for `_entity` on `_contract`
   * @param _entity Entity address
   * @param _contract Contract address
   * @return bytes32[] List of permissions
   */
  function permissionsOf(address _entity, address _contract) public view returns (bytes32[] memory) {
    uint8 counter = 0;
    bytes32[] memory tmp = new bytes32[](knownRoles.length);
    for (uint256 i = 0; i < knownRoles.length; i++) {
      if (hasPermission(_entity, _contract, knownRoles[i])) {
        tmp[counter] = knownRoles[i];
        counter += 1;
      }
    }

    bytes32[] memory permissionsList = new bytes32[](counter);
    for (uint256 j = 0; j < counter; j++) {
      permissionsList[j] = tmp[j];
    }

    return permissionsList;
  }

  /**
   * @notice Checks ACL on kernel or permission status
   * @dev Checks if `_entity` has permission `_role` on `_contract`
   * @param _entity Entity address
   * @param _contract Contract address
   * @param _role Role identifier
   * @return Boolean indicating whether the ACL allows the role or not
   */
  function hasPermission(
    address _entity,
    address _contract,
    bytes32 _role
  ) public view returns (bool) {
    // the address passed in has the permissions themselves
    bool personalPermission = permissions[_entity][_contract][_role];
    if (personalPermission) {
      return personalPermission;
    }
    // or we will check if any of the role registries have the permission
    for (uint256 counter = 0; counter < roleRegistries.length; counter++) {
      address registry = address(roleRegistries[counter]);
      bool registryPermission = permissions[registry][_contract][_role];
      if (registryPermission) {
        if (roleRegistries[counter].hasRole(_entity)) {
          return true;
        }
      }
    }
    // if, not, deny!
    return false;
  }

  /**
   * @notice Retrieves the role registry address for a given role
   * @dev Retrieves the role registry for the role `_role`
   * @param _role Identifier for the role mapped to a role registry
   * @return address of the role registry that corresponds to the role
   */
  function getRoleRegistryAddress(bytes32 _role) public view returns (address) {
    return roleToRoleRegistry[_role];
  }

  /**
   * @notice Sets the role registry address for a given role
   * @dev Sets the role registry for the role `_role` to `_address`. Access is limited by the ACL.
   * @param _role Identifier for the role mapped to a role registry
   * @param _address address of the role registry to put into the store
   */
  function setRoleRegistryAddress(bytes32 _role, address _address)
    public
    authWithCustomReason(ADD_ROLEREGISTRY_ROLE, 'Sender needs ADD_ROLEREGISTRY_ROLE')
  {
    roleToRoleRegistry[_role] = _address;

    if (!knownRole[_role]) {
      knownRoles.push(_role);
      knownRole[_role] = true;
    }
  }

  /**
   * @dev Internal createPermission for access inside the gatekeeper (on instantiation)
   */
  function _createPermission(
    address _entity,
    address _contract,
    bytes32 _role,
    address _manager
  ) internal {
    require(
      permissionManager[_contract][_role] == address(0x0),
      'only allow permission creation when it has no manager (has not been created before)'
    );
    _setPermission(_entity, _contract, _role, true);
    _setPermissionManager(_manager, _contract, _role);
  }

  /**
   * @dev Internal function called to actually save the permission
   */
  function _setPermission(
    address _entity,
    address _contract,
    bytes32 _role,
    bool _allowed
  ) internal {
    permissions[_entity][_contract][_role] = _allowed;
    emit SetPermission(_entity, _contract, _role, _allowed);
  }

  /**
   * @dev Internal function that sets management
   */
  function _setPermissionManager(
    address _newManager,
    address _contract,
    bytes32 _role
  ) internal {
    require(_newManager > address(0x0), '_newManager should be a real address');

    permissionManager[_contract][_role] = _newManager;
    emit ChangePermissionManager(_contract, _role, _newManager);
  }
}
