// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    constructor() ERC721("NFT", "NFT"){}

    uint256 public maxmint = 100;
    uint256 public currentMint;

    function mint(address to, uint256 amount) public onlyOwner {
        require (currentMint + amount <= maxmint, "max exceed");

        for (uint i=0; i<amount; i++){
            _safeMint(to, currentMint);
            currentMint++;
        }
    }

    function withdraw() public onlyOwner{

        payable(msg.sender).transfer(address(this).balance);
    }
}