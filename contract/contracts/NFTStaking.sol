// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "./NftCollection.sol";

contract NFTStaking is Ownable, IERC721Receiver {

    NftCollection nft;

    uint256 public totalStaked;

    struct Vault {
        address owner;
        uint256 tokenId;
        uint256 timestamp;
    }

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    constructor() {

    }
}
