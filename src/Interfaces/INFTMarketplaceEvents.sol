// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;
interface INFTMarketplaceEvents {
    event ItemListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);    event PriceUpdated(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event ListingCancelled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);
    event ItemSold(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event RevenueWithdrawn(address indexed recipient, uint256 indexed amount);
}