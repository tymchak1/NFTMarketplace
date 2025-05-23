// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace is Pausable, Ownable {
    event ItemListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event PriceUpdated(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event ListingCancelled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);
    event ItemSold(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event RevenueWithdrawn(address indexed recepient, uint256 indexed amount);

    uint256 public totalFees;
    uint256 public feeRate;

    error NotAnOwner();
    error NotListed(address nftContract, uint256 tokenId);
    error PriceCantBeZero();
    error NotApproved();
    error NFTNotAllowed();
    error WithdrawFailed();
    error InsufficientPayment();
    error FeeTooHigh();
    error AlreadyListed(address nftContract, uint256 tokenId);

    modifier onlyAllowedNFTs(address nftContract) {
        require(allowedNFTs[nftContract], NFTNotAllowed());
        _;
    }

    struct Listing {
        address seller;
        uint256 price;
        uint256 time;
    }

    mapping(address => mapping(uint256 => Listing)) listings;
    mapping(address => bool) allowedNFTs;


    function _isApproved(address nftContract, uint256 tokenId, address owner) internal view {
        IERC721 token = IERC721(nftContract);
        require(token.ownerOf(tokenId) == owner, NotAnOwner());
        require(
            token.getApproved(tokenId) == address(this) ||
            token.isApprovedForAll(owner, address(this)),
            NotApproved()
        );
    }

    function _listingProcces(address nftContract, uint256 tokenId, uint256 price) internal {
        _isApproved(nftContract, tokenId, msg.sender);
        require(price > 0, PriceCantBeZero());

        listings[nftContract][tokenId] = Listing(msg.sender, price, block.timestamp);
    }

    function getListing(address nftContract, uint256 tokenId) external view returns(address seller, uint256 price) {
        Listing memory listing = listings[nftContract][tokenId];
        return (listing.seller, listing.price);
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate < 1000, FeeTooHigh());
        feeRate = _feeRate;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(amount <= totalFees, "Not enough funds");

        (bool success, ) = payable(to).call{value: amount}("");
        require(success, WithdrawFailed());

        emit RevenueWithdrawn(to, amount);
    }

    function allowNFT(address nftContract) external onlyOwner {
        allowedNFTs[nftContract] = true;
    }

    function disallowNFT(address nftContract) external onlyOwner {
        allowedNFTs[nftContract] = false;
    }

    function listItem(address nftContract, uint256 tokenId, uint256 price) external whenNotPaused {
        Listing memory existing = listings[nftContract][tokenId];
        // якщо seller НЕ address(0), то лістинг вже існує
        require(existing.seller == address(0), AlreadyListed(nftContract, tokenId));
        _listingProcces(nftContract, tokenId, price);


        emit ItemListed(msg.sender, nftContract, tokenId, price);
    }

    function updateListingPrice(address nftContract, uint256 tokenId, uint256 newPrice) external whenNotPaused {
        _listingProcces(nftContract, tokenId, newPrice);

        emit PriceUpdated(msg.sender, nftContract, tokenId, newPrice);
    }

    function cancelListing(address nftContract, uint256 tokenId) external whenNotPaused {
        Listing memory listedItem = listings[nftContract][tokenId];
        require(listedItem.seller != address(0), NotListed(nftContract, tokenId));
        require(listedItem.seller == msg.sender, NotAnOwner());

        delete listings[nftContract][tokenId];
        emit ListingCancelled(msg.sender, nftContract, tokenId);
    }

    function buyItem(address nftContract, uint256 tokenId) external payable whenNotPaused {
        Listing memory item = listings[nftContract][tokenId];
        require(item.price > 0, NotListed(nftContract, tokenId));
        require(msg.value == item.price, InsufficientPayment());

        IERC721 token = IERC721(nftContract);
        require(token.ownerOf(tokenId) == item.seller, NotAnOwner());
        _isApproved(nftContract, tokenId, item.seller);

        uint256 mpRevenue = (item.price * feeRate) / 1000;
        uint256 sellerEarnings = item.price - mpRevenue;

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