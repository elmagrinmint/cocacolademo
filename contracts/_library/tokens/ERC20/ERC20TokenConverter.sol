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

import '../../authentication/RoleRegistry.sol';
import './ERC20Token.sol';

contract ERC20TokenConverter {
  // Needs the MINT_ROLE on the UnrestrictedCoin
  // Needs the BURN_ROLE on the to be relayed coins

  RoleRegistry roleRegistry;

  event ConvertingTransfer(
    address indexed _from,
    address _fromToken,
    address indexed _to,
    address _toToken,
    uint256 _amount
  );

  constructor(address _roleRegistry) {
    roleRegistry = RoleRegistry(_roleRegistry);
  }

  function convert(
    address _from,
    address _fromToken,
    address _to,
    address _toToken,
    uint256 _amount
  ) public {
    require(roleRegistry.hasRole(_to), '_to needs to be an authorised party');
    require(_fromToken == msg.sender, '_fromToken should be the sender');
    ERC20Token fromToken = ERC20Token(_fromToken);
    require(fromToken.burn(_from, _amount), 'burn was unsuccesfull');
    ERC20Token toToken = ERC20Token(_toToken);
    require(toToken.mint(_to, _amount), 'mint was unsuccesfull');
    emit ConvertingTransfer(_from, _fromToken, _to, _toToken, _amount);
  }
}
