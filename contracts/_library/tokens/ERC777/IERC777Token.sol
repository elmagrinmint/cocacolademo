// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract IERC777Token {
  bytes32 public constant MINT_ROLE = 'MINT_ROLE';
  bytes32 public constant BURN_ROLE = 'BURN_ROLE';
  bytes32 public constant MANAGE_OPERATOR_ROLE = 'MANAGE_OPERATOR_ROLE';

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes userData,
    bytes operatorData
  );
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes userData, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

  function balanceOf(address owner) public view virtual returns (uint256);

  function send(address to, uint256 amount) public virtual;

  function send(
    address to,
    uint256 amount,
    bytes memory userData
  ) public virtual;

  function authorizeOperator(address operator) public virtual;

  function revokeOperator(address operator) public virtual;

  function isOperatorFor(address operator, address tokenHolder) public view virtual returns (bool);

  function operatorSend(
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) public virtual;
}
