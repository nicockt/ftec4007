// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721Pausable, Ownable, ERC721Burnable, EIP712, ERC721Votes {
    uint256 private _nextTokenId;
    mapping(address => uint256[]) private _mintedTokens;
    uint256 private _tokenIdCounter;
    uint256 public maxmint = 10000;
    uint256 public currentMint;

    constructor(address initialOwner)
        ERC721("NFT", "FTC")
        Ownable(initialOwner)
        EIP712("NFT", "1")
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 numberOfTokens) public onlyOwner returns (uint256[] memory) {
        require(currentMint + numberOfTokens <= maxmint, "Max limit exceeded");
        
        uint256[] memory mintedTokenIds = new uint256[](numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter;
            _safeMint(to, tokenId);
            mintedTokenIds[i] = tokenId;
            currentMint++;
            _tokenIdCounter++;
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
        override(ERC721, ERC721Enumerable, ERC721Pausable, ERC721Votes)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable, ERC721Votes)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}