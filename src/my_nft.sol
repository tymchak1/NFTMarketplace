// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyCollection is ERC721, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    uint256 private _price = 0.001 ether;
    uint256 private _totalSupply = 15;

    mapping(address => uint256) private _amountMinted;

    constructor(address initialOwner)
        ERC721("myCollection", "MC")
        Ownable(initialOwner)
    {}

    function _baseURI() internal pure override returns (string memory) {
        return " ipfs://QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/";
    }

    function safeMint(address to) public onlyOwner returns (uint256) {
        require(_nextTokenId < _totalSupply, "Sold out");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function mint(address to) public payable returns (uint256) {
        require(_nextTokenId < _totalSupply, "Sold out");
        require(msg.value == _price, "Insufficent payment");
        require(_amountMinted[to] < 2, "Max amount mindted");

        _amountMinted[to] += 1; 
 
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;     
    }

    function withdraw(address recepient, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Not enough balance");

        (bool success, ) = payable(recepient).call{value : amount}("");
        require(success, "Withdraw failed");
    }

}