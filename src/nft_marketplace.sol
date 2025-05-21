// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract NFTMarketplace {
    event ItemListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event ListingCancelled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);
    event ItemSold(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);

    struct Listing {
        address seller;
        uint256 price;
    }
        // nftContract => tokenId => Listing(seller, price)
    mapping(address => mapping(uint256 => Listing)) listings;

    function listItem(address nftContract, uint256 tokenId, uint256 price) {
        IERC721 token = IERC721(nftContract);

        require (token.ownerOf(tokenId) == msg.sender, "Not the owner"); // owner check
        require (
            token.getApproved(tokenId) == address(this) ||
            token.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[nftContract][tokenId] = Listing(msg.sender, price);
    }

    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing memory listedItem = listings[nftContract][tokenId];
        require(listedItem.seller != address(0), "Not listed");
        require(listedItem.seller == msg.sender, "Not an owner");

        delete listings[nftContract][tokenId];f
    }

    function buyItem(address nftContract, uint256 tokenId) external {
        Listing memory item = listings[nftContract][tokenId];
        require(item.price > 0, "Not listed");
        require(msg.value == item.price, "Insufficient payment");

        IERC721 token = IERC721(nftContract);

        require(token.ownerOf(tokenId) == item.seller, "Seller is no longer an owner");
        require (
            token.getApproved(tokenId) == address(this) ||
            token.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        token.safeTransferFrom(item.seller, msg.sender, tokenId);

        payable(item.seller).transfer(msg.value);

        delete listings[nftContract][tokenId];
    }
}