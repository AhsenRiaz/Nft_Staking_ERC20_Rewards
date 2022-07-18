// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IOwnable.sol";

interface ICollection is IERC721Enumerable, IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function mint(address to_, uint256 mintAmount_) external payable;

    function walletOfOwner(address owner_)
        external
        view
        returns (uint256[] calldata);

    function tokenURI(uint256 tokenId) external view returns (string calldata);

    function setMaxMintAmount(uint256 _newMaxMintAmount) external;

    function setBaseURI(string calldata _newBaseURI) external;

    function setBaseExtension(string calldata _newExtension) external;

    function pause(bool _state) external;

    function withdraw() external payable;
}
