// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; //Imported in case burning NFTs is used
import "@openzeppelin/contracts/access/Ownable.sol";



    interface IManagment{
        function linkFControllerstoLot(uint256, uint256[3] memory) external;
    }

contract FControllersLOT is ERC721URIStorage, Ownable{
    uint public tokenCount;
    IManagment public Management;
    constructor () ERC721("Flight Controllers LOT", "FCLOT"){

    } 

     modifier onlyManagementSmartContract{
        require(msg.sender == address(Management), "Only the Trade Management smart contract can run this function");
        _;
    }


    function SetManagementSC(address _mgmtsc) external onlyOwner{
        Management = IManagment(_mgmtsc);

    }

    function mint(string memory _tokenURI, uint256[3] memory _childIDs, address _LotCreator) external onlyManagementSmartContract returns(uint, string memory) {
        tokenCount++;
        _safeMint(_LotCreator, tokenCount); 
        _setTokenURI(tokenCount, _tokenURI);
        Management.linkFControllerstoLot(tokenCount, _childIDs);
        //TradeManagement.UpdateProducerMintingBalance(msg.sender, _childID, 1);
        
        return(tokenCount, _tokenURI);
    } 

        

}