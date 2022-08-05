// SPDX-License-Identifier: GPL-3.0
// internal one used memory for function's paremeters
// external one uses calldata for functions's parameters
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string private baseURI;
    string private baseExtension = ".json";
    uint256 private maxSupply = 10000;
    uint256 private maxMintAmount = 5;
    bool private paused = false;

    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function addCurrency(IERC20 _paytoken, uint256 _costvalue)
        external
        onlyOwner
    {
        require(_costvalue > 0, "MyNFT: cost value less than zero");

        AllowedCrypto.push(
            TokenInfo({paytoken: _paytoken, costvalue: _costvalue})
        );
    }

    function mint(address to_, uint256 mintAmount_, uint256 _pid) external payable {
        uint256 totalSupply = totalSupply();
        TokenInfo storage tokens = AllowedCrypto[_pid];
        require(!paused, "MyNFT: minting paused");
        require(mintAmount_ > 0, "MyNFT: mintAmount < 0");
        require(
            mintAmount_ <= maxMintAmount,
            "MyNFT: mintAmount > maxMintAmount"
        );
        require(
            totalSupply + mintAmount_ <= maxSupply,
            "MyNFT: totalSupply > maxSupply"
        );
        IERC20 paytoken = tokens.paytoken;
        uint256 cost = tokens.costvalue;
        if (msg.sender != owner()) {
            require(msg.value == mintAmount_ * cost, "MyNFT: fees < required");
        }

        for (uint i = 1; i <= mintAmount_; i++) {
            paytoken.transferFrom(msg.sender, address(this), cost);
            _safeMint(to_, totalSupply + i);
        }
    }

    function walletOfOwner(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistant token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // onlyOwner
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw(uint _pid) public payable onlyOwner {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken = tokens.paytoken;
        uint256 balance = paytoken.balanceOf(address(this));
        paytoken.transfer(msg.sender, balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://EE5MmqVp5MmqVp7ZRMBBizicVh9ficVh9fjUofWicVh9f/";
    }

}
