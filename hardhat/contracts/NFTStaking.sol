// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./ICollection.sol";
import "./IERC20Rewards.sol";

contract NFTStaking is Ownable, IERC721Receiver {
    uint256 private _totalStaked;

    struct Vault {
        ICollection nft;
        IERC20Rewards token;
        string name;
    }

    Vault[] private _vaultInfo;

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
        address owner;
    }

    mapping(uint256 => Stake) private _vault;

    event NFTStaked(address from, address to, uint256 tokenId, uint256 time);
    event NFTUnstaked(address from, address to, uint256 tokenId, uint256 time);
    event Claimed(address from, uint256 earned);

    modifier isValidAddress() {
        require(msg.sender != address(0), "NFTStaking, sender is zero address");
        _;
    }

    function addVault(
        ICollection _nft,
        IERC20Rewards _token,
        string calldata _name
    ) external onlyOwner isValidAddress {
        _vaultInfo.push(Vault({nft: _nft, token: _token, name: _name}));
    }

    function stake(uint256[] calldata tokenIds, uint256 _pid)
        external
        isValidAddress
    {
        require(_pid < _vaultInfo.length);
        require(tokenIds.length > 0, "NFTStaking: tokenIds < 0");
        uint256 tokenId;
        _totalStaked += tokenIds.length;

        Vault storage vaultId = _vaultInfo[_pid];

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            require(
                vaultId.nft.ownerOf(tokenId) == msg.sender,
                "NFTStaking: nft does not belong to sender"
            );
            require(_vault[tokenId].tokenId == 0, "NFTStaking: staked already");

            _vault[tokenId] = Stake({
                tokenId: tokenId,
                timestamp: block.timestamp,
                owner: msg.sender
            });

            vaultId.nft.transferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, address(this), tokenId, block.timestamp);
        }
    }

    function claim(
        address account,
        uint256[] calldata tokenIds,
        uint256 _pid
    ) external isValidAddress {
        require(_pid < _vaultInfo.length, "vauldId > vaultInfo.length");
        require(tokenIds.length > 0, "NFTStaking: tokenIds < 0");

        _claim(account, tokenIds, _pid, false);
    }

    function claimForAddress(
        address account,
        uint256[] calldata tokenIds,
        uint256 _pid
    ) external isValidAddress {
        require(_pid < _vaultInfo.length, "vauldId > vaultInfo.length");
        require(tokenIds.length > 0, "NFTStaking: tokenIds < 0");

        _claim(account, tokenIds, _pid, true);
    }

    function claimAndUnstake(
        address account,
        uint256[] calldata tokenIds,
        uint256 _pid
    ) external isValidAddress {
        require(_pid < _vaultInfo.length, "vauldId > vaultInfo.length");
        require(tokenIds.length > 0, "NFTStaking: tokenIds < 0");

        _claim(account, tokenIds, _pid, true);
    }

    function earningInfo(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[1] memory)
    {
        require(tokenIds.length > 0, "NFTStaking: tokenIds < 0");
        uint earned = 0;
        uint tokenId;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory _stake = _vault[tokenId];

            uint stakedAt = _stake.timestamp;
            earned += (100000 * (block.timestamp - stakedAt)) / 1 days;
        }
        return [earned];
    }

    // should never be used inside of transaction because of gas fee
    function balanceOf(address account, uint256 _pid)
        public
        view
        returns (uint256)
    {
        uint256 balance = 0;
        Vault storage vaultid = _vaultInfo[_pid];
        uint256 supply = vaultid.nft.totalSupply();

        for (uint i = 1; i <= supply; i++) {
            if (_vault[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    function tokensOfOwner(address account, uint _pid)
        external
        view
        returns (uint256[] memory)
    {
        uint index = 0;

        Vault memory vaultId = _vaultInfo[_pid];
        uint256 supply = vaultId.nft.totalSupply();
        uint256[] memory tokenIds = new uint256[](supply);

        for (uint i = 0; i < tokenIds.length; i++) {
            if (_vault[i].owner == account) {
                tokenIds[index] = _vault[i].tokenId;
                index += 1;
            }
        }

        uint256[] memory ownerTokenIds = new uint256[](index);

        for (uint i = 0; i < ownerTokenIds.length; i++) {
            ownerTokenIds[i] = tokenIds[i];
        }
        return ownerTokenIds;
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

    function _unstakeMany(
        address account,
        uint256[] calldata tokenIds,
        uint256 _pid
    ) internal isValidAddress {
        _totalStaked -= tokenIds.length;
        uint tokenId;
        Vault storage vaultId = _vaultInfo[_pid];

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = _vault[tokenId];

            require(
                staked.owner == msg.sender,
                "NFTStaking: nft does not belong to sender"
            );
            require(staked.tokenId != 0, "NFTStaking: not staked");

            delete _vault[tokenId];

            vaultId.nft.transferFrom(address(this), account, tokenId);
            emit NFTUnstaked(address(this), account, tokenId, block.timestamp);
        }
    }

    function _claim(
        address account,
        uint256[] calldata tokenIds,
        uint256 _pid,
        bool _unstake
    ) internal {
        uint256 tokenId;
        uint256 earned;
        Vault storage vaultId = _vaultInfo[_pid];

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake storage _stake = _vault[tokenId];

            require(
                _stake.owner == account,
                "NFTStaking: nft does not belong to sender"
            );
            require(_stake.tokenId != 0, "NFTStaking: not claimed");

            uint256 stakedAt = _stake.timestamp;
            earned += (100000 ether * (block.timestamp - stakedAt)) / 1 days;

            if (earned > 0) {
                earned = earned / 10;
                vaultId.token.mint(account, earned);
            }
            if (earned > 0 && _unstake == true) {
                vaultId.token.mint(account, earned);
                _unstakeMany(account, tokenIds, _pid);
            }

            emit Claimed(account, earned);
        }
    }
}
