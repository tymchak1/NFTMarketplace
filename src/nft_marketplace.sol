// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract NFTMarketplace is Pausable {
    event ItemListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event PriceUpdated(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event ListingCancelled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);
    event ItemSold(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event RevenueWithdrawn(address indexed recepient, uint256 indexed amount);

    uint256 public totalFees;
    address public owner;
    uint256 public feeRate;

    constructor() {
        owner = msg.sender;
    }


    modifier onlyAllowedNFTs(address nftContract) {
        require(allowedNFTs[nftContract] == true, "NFT not allowed");
        _;
    }

    struct Listing {
        address seller;
        uint256 price;
    }
        // nftContract => tokenId => Listing(seller, price)
    mapping(address => mapping(uint256 => Listing)) listings;
    mapping(address => bool) allowedNFTs;

    function _isApproved(address nftContract, uint256 tokenId, address owner) internal view {
        IERC721 token = IERC721(nftContract);

        require (token.ownerOf(tokenId) == owner, "Not an owner"); // owner check
        require (
            token.getApproved(tokenId) == address(this) ||
            token.isApprovedForAll(owner, address(this)),
            "Marketplace not approved"
        );
    }

    function getListing(address nftContract, uint256 tokenId) external view returns(address seller, uint256 price) {
        Listing memory listing = listings[nftContract][tokenId];
        return(listing.seller, listing.price);
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate < 1000, "Fee is too high"); // Макс 99.9%
        feeRate = _feeRate;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(amount <= totalFees, "Not enough funds");

        (bool success, ) = payable(to).call{value : amount}("");
        require(success, "Withdraw failed");

        emit RevenueWithdrawn(to, amount);
    }

    function allowNFT(address nftContract) external onlyOwner {
        allowedNFTs[nftContract] = true;
    }

    function disallowNFT(address nftContract) external onlyOwner {
        allowedNFTs[nftContract] = false;
    }

    function listItem(address nftContract, uint256 tokenId, uint256 price) external whenNotPaused {
        _isApproved(nftContract, tokenId, msg.sender);
        require(price > 0, "Price must be greater than zero");
        
        listings[nftContract][tokenId] = Listing(msg.sender, price);

        emit ItemListed(msg.sender, nftContract, tokenId, price);
    }

    function updateListingPrice(address nftContract, uint256 tokenId, uint256 newPrice) external whenNotPaused {
        _isApproved(nftContract, tokenId, msg.sender);

        require(newPrice > 0, "Price must be greater than zero");

        listings[nftContract][tokenId] = Listing(msg.sender, newPrice);
        emit PriceUpdated(msg.sender, nftContract, tokenId, newPrice);
    }

    function cancelListing(address nftContract, uint256 tokenId) external whenNotPaused {
        Listing memory listedItem = listings[nftContract][tokenId];
        require(listedItem.seller != address(0), "Not listed");
        require(listedItem.seller == msg.sender, "Not an owner");

        delete listings[nftContract][tokenId];

        emit ListingCancelled(msg.sender, nftContract, tokenId);
    }

    function buyItem(address nftContract, uint256 tokenId) external payable whenNotPaused {
        uint256 mpRevenue;
        uint256 sellerEarnings;

        Listing memory item = listings[nftContract][tokenId];
        require(item.price > 0, "Not listed");
        require(msg.value == item.price, "Insufficient payment");

        IERC721 token = IERC721(nftContract);

        require(token.ownerOf(tokenId) == item.seller, "Seller is no longer an owner");
        _isApproved(nftContract, tokenId, item.seller);
        
        mpRevenue = (item.price * feeRate) / 1000;
        sellerEarnings = item.price - mpRevenue;

        token.safeTransferFrom(item.seller, msg.sender, tokenId);
        payable(item.seller).transfer(sellerEarnings);

        totalFees += mpRevenue;

        delete listings[nftContract][tokenId];

        emit ItemSold(msg.sender, nftContract, tokenId, msg.value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}