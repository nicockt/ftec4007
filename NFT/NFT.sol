// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    constructor(address initialOwner)
        ERC721("NFT", "Team10")
        Ownable(initialOwner)
    {}
    uint256 public maxmint = 10;
    uint256 public currentMint;
    uint256 private _nextTokenId;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256[]) private _mintedTokens;

    function _baseURI() internal pure override returns (string memory) {
        return "https://team10.com/";
    }

function safeMint(address to, uint256 numberOfTokens) public onlyOwner returns (uint256[] memory) {
        require(currentMint + numberOfTokens <= maxmint, "Max limit exceeded");
        
        uint256[] memory mintedTokenIds = new uint256[](numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
            mintedTokenIds[i] = tokenId;
            currentMint++;
            _tokenIdCounter.increment();
        }

        _mintedTokens[to] = mintedTokenIds;

        return mintedTokenIds;
    }

    function getTokenIdsByOwner(address owner) public view returns (uint256[] memory) {
        return _mintedTokens[owner];
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
