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

contract Converter {
  function addressToString(address data) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(data)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) {
      return bytes1(uint8(b) + 0x30);
    }
    return bytes1(uint8(b) + 0x57);
  }

  function bytes32ToString(bytes32 x) internal pure returns (string memory) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 j = 0; j < 32; j++) {
      bytes1 charr = bytes1(bytes32(uint256(x) * 2**(8 * j)));
      if (charr != 0) {
        bytesString[charCount] = charr;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (uint256 k = 0; k < charCount; k++) {
      bytesStringTrimmed[k] = bytesString[k];
    }
    return string(bytesStringTrimmed);
  }

  function uintToString(uint256 i) internal pure returns (string memory) {
    unchecked {
      if (i == 0) {
        return '0';
      }

      uint256 j = i;
      uint256 length;
      while (j != 0) {
        length++;
        j /= 10;
      }

      uint256 ii = i;
      bytes memory bstr = new bytes(length);
      uint256 k = length - 1;
      while (ii != 0) {
        bstr[k--] = bytes1(uint8(48 + (ii % 10)));
        ii /= 10;
      }

      return string(bstr);
    }
  }
}
