// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; //Imported in case burning NFTs is used
import "@openzeppelin/contracts/access/Ownable.sol";


contract BatteriesNFT is ERC721URIStorage, Ownable{
    uint public tokenCount;
    constructor () ERC721("Batteries NFTs", "BTR"){} // The constructor uses the imported ERC721 contract which requires two inputs in its constructor, the name and symbol of the NFT
    
    //Optional: Make only authorized users mint Raw Genomics Data NFT
    function mint(string memory _tokenURI) external returns(uint){
        tokenCount++;
        _safeMint(msg.sender, tokenCount); 
        _setTokenURI(tokenCount, _tokenURI);
        return(tokenCount);
    } 



}