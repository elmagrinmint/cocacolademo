// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract DigitalTwin {
  bytes32 public constant DIGITAL_TWIN = 'DIGITAL_TWIN';
  bytes32 public constant UPGRADEABLE_REGISTRY_TARGET = 'UPGRADEABLE_REGISTRY_TARGET';

  struct Claim {
    string DID;
    address owner;
    bytes32 kind;
    address[] assertions;
    uint256 createdAt;
    string identifier;
  }

  /**
   * Events
   */
  event ClaimWithIdentifierCreated(string DID, bytes32 kind, string identifier);
  event ClaimAsserted(string DID, address identity);
  event ClaimWithIdentifierUpdated(string DID, string identifier);

  Claim[] internal _claimRegistry;

  // Beware, the claimIndex is 1-based!
  // Obviously a tradeoff, the main benefit is that by making it 1-based, 0 acts as an invalid index.
  // This means we can use this mapping to check if the DID is known or not:
  // _claimIndex[NON_EXISTING_DID] will resolve to 0 -> which is an invalid index -> non existing DID
  mapping(string => uint256) internal _claimIndex;

  function addClaimWithIdentifier(
    string memory DID,
    bytes32 kind,
    string memory identifier
  ) internal {
    string[] memory DIDs = new string[](1);
    DIDs[0] = DID;

    bytes32[] memory kinds = new bytes32[](1);
    kinds[0] = kind;

    string[] memory identifiers = new string[](1);
    identifiers[0] = identifier;

    addClaimsWithIdentifier(DIDs, kinds, identifiers);
  }

  function addClaimsWithIdentifier(
    string[] memory DIDs,
    bytes32[] memory kinds,
    string[] memory identifiers
  ) internal {
    require(DIDs.length == kinds.length, 'Invalid array length input');
    require(kinds.length == identifiers.length, 'Invalid array length input');
    require(DIDs.length > 0, 'Empty argument error');

    for (uint256 i = 0; i < DIDs.length; i++) {
      string memory DID = DIDs[i];
      bytes32 kind = kinds[0];
      string memory identifier = identifiers[0];

      require(kind.length > 0, 'Invalid kind');
      require(bytes(DID).length > 0, 'Invalid DID');
      require(bytes(identifier).length > 0, 'Invalid identifier');

      require(_claimIndex[DID] == 0, 'Claim already exists');
      _claimRegistry.push();
      uint256 claimIndex = _claimRegistry.length;

      Claim storage c = _claimRegistry[claimIndex - 1];
      c.DID = DID;
      c.identifier = identifier;
      c.kind = kind;
      c.createdAt = block.timestamp;
      c.owner = msg.sender;

      _claimIndex[DID] = claimIndex;

      emit ClaimWithIdentifierCreated(c.DID, kind, c.identifier);
    }
  }

  function assertClaim(string memory DID) internal {
    require(_claimIndex[DID] != 0, 'Unknown field');

    uint256 claimIndex = _claimIndex[DID];
    Claim storage c = _claimRegistry[claimIndex - 1];

    c.assertions.push(msg.sender);

    emit ClaimAsserted(DID, msg.sender);
  }

  function editClaimWithIdentifier(string memory DID, string memory identifier) internal {
    require(_claimIndex[DID] != 0, 'Unknown field');

    uint256 claimIndex = _claimIndex[DID];
    Claim storage c = _claimRegistry[claimIndex - 1];
    c.identifier = identifier;

    emit ClaimWithIdentifierUpdated(c.DID, c.identifier);
  }

  function getClaimWithIdentifier(string memory DID) public view returns (string memory identifier) {
    require(_claimIndex[DID] != 0, 'Unknown field!');

    uint256 claimIndex = _claimIndex[DID];
    Claim storage c = _claimRegistry[claimIndex - 1];

    return c.identifier;
  }

  function claimExists(string memory DID) public view returns (bool) {
    return _claimIndex[DID] > 0;
  }
}
