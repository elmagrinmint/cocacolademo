// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../ERC777/IERC777Token.sol';

/**
 * Please note that for simplicity, and because we won't be using this contract with an enormous
 * amount of tranches all functions marked external were made public
 */
abstract contract IERC1410Token is IERC777Token {
  event SentByTranche(
    bytes32 indexed fromTranche,
    address operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes data,
    bytes operatorData
  );

  event ChangedTranche(bytes32 indexed fromTranche, bytes32 indexed toTranche, uint256 amount);

  event AuthorizedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
  event RevokedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);

  function balanceOf(address tokenHolder) public view virtual override returns (uint256);

  function balanceOfByTranche(bytes32 tranche, address tokenHolder) public view virtual returns (uint256);

  function tranchesOf(address tokenHolder) public view virtual returns (bytes32[] memory);

  function sendByTranche(
    bytes32 tranche,
    address to,
    uint256 amount,
    bytes memory data
  ) public virtual returns (bytes32);

  function sendByTranches(
    bytes32[] memory tranches,
    address to,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual returns (bytes32[] memory);

  function operatorSendByTranche(
    bytes32 tranche,
    address from,
    address to,
    uint256 amount,
    bytes memory data,
    bytes memory operatorData
  ) public virtual returns (bytes32);

  function operatorSendByTranches(
    bytes32[] memory tranches,
    address from,
    address to,
    uint256[] memory amounts,
    bytes memory data,
    bytes memory operatorData
  ) public virtual returns (bytes32[] memory);

  function getDefaultTranches(address tokenHolder) public view virtual returns (bytes32[] memory);

  function setDefaultTranches(bytes32[] memory tranches) public virtual;

  function defaultOperatorsByTranche(bytes32 tranche) public view virtual returns (address[] memory);

  function authorizeOperatorByTranche(bytes32 tranche, address operator) public virtual;

  function revokeOperatorByTranche(bytes32 tranche, address operator) public virtual;

  function isOperatorForTranche(
    bytes32 tranche,
    address operator,
    address tokenHolder
  ) public view virtual returns (bool);

  function hasTranche(address tokenHolder, bytes32 tranche) public view virtual returns (bool);

  function addTranche(address tokenHolder, bytes32 tranche) public virtual;
}
