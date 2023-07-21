// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import 'hardhat/console.sol';
import { PGBountyState, IPGBountiesHandler } from './interfaces/IPGBountiesHandler.sol';

contract BountyContract is ERC721URIStorage {

  error BountyDoesntExist();
  error BountyIsNotOpened();

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address payable owner;

  mapping(uint256 => Bounty) private idBounty;

  struct Bounty {
    uint256 tokenId;
    address payable owner;
    address payable contributor;
    uint256 reward;
    string criteria;
    string description;
    PGBountyState state;
  }

  event idBountyCreated(
    uint256 indexed tokenId,
    address owner,
    address contributor,
    uint256 reward,
    string criteria,
    string description,
    string attestationHash,
    PGBountyState state
  );

  event ProofSubmitted(
    uint256 indexed tokenId,
    address indexed contributor,
    string attestationHash
  );

  constructor() ERC721('Token', 'NFT') {
    owner = payable(msg.sender);
  }

  function openBounty(
    uint256 reward,
    string calldata criteria,
    string calldata description
  ) public payable returns (uint256) {
    require(reward > 0, 'The reward must be bigger than 0.');

    _tokenIds.increment();

    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);

    createBounty(newTokenId, reward, criteria, description);

    return newTokenId;
  }

  function submitProof(uint256 _bountyId, string memory _attestationHash) external {
    Bounty storage bounty = idBounty[bountyId];
    if (bounty.owner == address(0)) revert BountyDoesntExist();
    if (!bounty.state != PGBountyState.OPEN) revert BountyIsNotOpened();

    bounty.attestationHash = _attestationHash;
    bounty.state = PGBountyState.SUBMITTED;
    // TODO: set new timer
    bounty.contributor = msg.sender;

    emit ProofSubmitted(bountyId, msg.sender, attestationHash);
  }

  function createBounty(
    uint256 tokenId,
    uint256 reward,
    string calldata criteria,
    string calldata description
  ) private {
    idBounty[tokenId] = Bounty(
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      reward,
      criteria,
      description,
      "",
      PGBountyState.OPEN
    );
  }

  function fetchBounties() public view returns (Bounty[] memory) {
    uint256 itemCount = _tokenIds.current();
    uint256 currentIndex = 0;

    Bounty[] memory items;

    for (uint256 i = 0; i < itemCount; i++) {
      if (idBounty[i + 1].state == PGBountyState.OPEN) {
        uint256 currentId = i + 1;

        Bounty storage currentItem = idBounty[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return items;
  }
}
