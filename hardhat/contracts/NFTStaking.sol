// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./ICollection.sol";
import "./IERC20Rewards.sol";

contract NFTStaking is Ownable, IERC721Receiver {
    ICollection public nft;
    IERC20Rewards public token;

    uint256 public totalStaked;

    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timestamp;
    }

    mapping(uint256 => Stake) public vault;

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    modifier validAddress() {
        require(msg.sender != address(0), "NFTStaking: sender is zero address");
        _;
    }

    constructor(ICollection nft_, IERC20Rewards token_) {
        nft = nft_;
        token = token_;
    }

    function stake(uint256[] calldata tokenIds) external validAddress {
        uint256 tokenId;
        totalStaked += tokenIds.length;

        require(tokenIds.length > 0, "NFTStaking: tokenIds < 0");

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            require(
                nft.ownerOf(tokenId) == msg.sender,
                "NFTStaking: nft does not belong to sender"
            );
            require(vault[tokenId].tokenId == 0, "NFTStaking: already staked");

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: tokenId,
                timestamp: block.timestamp
            });

            nft.transferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, tokenId, block.timestamp);
        }
    }

    function claim(address account, uint256[] calldata tokenIds) external {
        _claim(account, tokenIds, false);
    }

    function claimForAddress(address account, uint256[] calldata tokenIds)
        external
    {
        _claim(account, tokenIds, false);
    }

    function unstake(address account, uint256[] calldata tokenIds) external {
        _claim(account, tokenIds, true);
    }

    function earningInfo(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[1] memory info)
    {
        require(tokenIds.length > 0, "NFTStake: tokenIds.length < 0");
        uint256 tokenId;
        uint256 earned = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(
                staked.owner == msg.sender,
                "NFTStaking: nft does not belong to sender"
            );
            require(staked.tokenId != 0, "NFTStaking: not staked");
            uint256 stakedAt = staked.timestamp;
            earned += (10000 ether * (block.timestamp - stakedAt)) / 1 days;
        }
        return [earned];
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 supply = nft.totalSupply();
        uint balance = 0;
        for (uint i = 1; i <= supply; i++) {
            if (vault[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    function tokensOfOwner(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256 supply = nft.totalSupply();
        uint balance = 0;
        uint index = 0;

        for (uint i = 1; i <= supply; i++) {
            if (vault[i].owner == account) {
                balance += 1;
            }
        }

        uint256[] memory tokens = new uint256[](balance);

        for (uint i = 0; i < tokens.length; i++) {
            if (vault[i].owner == account) {
                tokens[index] = vault[i].tokenId;
                index += 1;
            }
        }

        return tokens;
    }

    function _unstakeMany(address account, uint256[] calldata tokenIds)
        internal
    {
        uint256 tokenId;
        totalStaked -= tokenIds.length;

        for (uint i = 0; i <= tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(
                staked.owner == account,
                "NFTStaking: nft does not belong to sender"
            );

            delete vault[tokenId];
            nft.transferFrom(address(this), account, tokenId);
            emit NFTUnstaked(account, tokenId, block.timestamp);
        }
    }

    function _claim(
        address account,
        uint256[] calldata tokenIds,
        bool _unstake
    ) internal {
        uint tokenId;
        uint256 earned = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.tokenId != 0, "NFTStaked: not staked");
            require(
                staked.owner == msg.sender,
                "NFTStake: nft does not belong to sender"
            );
            uint256 stakedAt = staked.timestamp;
            earned += (10000 ether * (block.timestamp - stakedAt)) / 1 days;
        }

        if (earned > 0) {
            earned = earned / 10000;
            token.mint(account, earned);
        }

        if (_unstake) {
            _unstakeMany(account, tokenIds);
        }

        emit Claimed(account, earned);
    }

    // it will return a selector (a bytes4 hash) which will be the hash of the name of calling function whenever it will receive an nft. so that the contract which send the nft knows that it is a reliable contract and it has received the nft.
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(
            from == address(0x0),
            "NFTStaking: cannot send nft directly to vault"
        );
        return IERC721Receiver.onERC721Received.selector;
    }
}
