// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INFTMarketplaceEvents} from "./interfaces/INFTMarketplaceEvents.sol";
import {Listing} from "./Structs/Listing.sol";

/// @title NFT Marketplace Contract
/// @author tymchakn
/// @notice This contract allows users to list, buy, and manage NFTs in a marketplace.
contract NFTMarketplace is Pausable, Ownable, INFTMarketplaceEvents {
    
    /// @notice Deploys the NFT marketplace and sets the deployer as the contract owner.
    /// @dev Initializes the Ownable parent with the deployer's address.
    constructor() Ownable(msg.sender) {}

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
    error TransferFailed();
    error NotSeller();

    modifier onlyAllowedNFTs(address nftContract) {
        require(allowedNFTs[nftContract], NFTNotAllowed());
        _;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => bool) public allowedNFTs;


    function _isApproved(address nftContract, uint256 tokenId, address owner) internal view {
        IERC721 token = IERC721(nftContract);
        require(token.ownerOf(tokenId) == owner, NotAnOwner());
        if (
            token.getApproved(tokenId) != address(this) &&
            !token.isApprovedForAll(owner, address(this))
        ) {
            revert NotApproved();
        }
    }

    function _listingProcess(address nftContract, uint256 tokenId, uint256 price) internal {
        _isApproved(nftContract, tokenId, msg.sender);
        require(price > 0, PriceCantBeZero());

        listings[nftContract][tokenId] = Listing(msg.sender, price, block.timestamp);
    }

    /// @notice Returns the listing details for a given NFT.
    /// @param nft The address of the NFT contract.
    /// @param tokenId The token ID of the NFT.
    /// @return The Listing struct containing seller, price, and timestamp.
    function getListing(address nft, uint256 tokenId) external view returns (Listing memory) {
        return listings[nft][tokenId];
    }

    /// @notice Sets the marketplace fee rate (in tenths of a percent).
    /// @dev Only callable by the contract owner. Max value is 999 (99.9%)
    /// @param _feeRate The fee rate to set, e.g., 50 means 5.0%.
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate < 1000, FeeTooHigh());
        feeRate = _feeRate;
    }
    /// @notice Withdraws accumulated marketplace fees to a given address.
    /// @dev Only callable by the contract owner.
    /// @param to The address to receive the withdrawn funds.
    /// @param amount The amount of ether to withdraw.
    /// @custom:error WithdrawFailed Reverts if the ETH transfer fails.
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(amount <= totalFees, "Not enough funds");

        totalFees -= amount;

        (bool success, ) = payable(to).call{value: amount}("");
        require(success, WithdrawFailed());

        emit RevenueWithdrawn(to, amount);
    }
    /// @notice Allows a specific NFT contract to be used on the marketplace.
    /// @dev Only callable by the contract owner.
    /// @param nftContract The address of the NFT contract to allow.
    function allowNFT(address nftContract) external onlyOwner {
        allowedNFTs[nftContract] = true;
    }
    /// @notice Disallows a specific NFT contract from being used on the marketplace.
    /// @dev Only callable by the contract owner.
    /// @param nftContract The address of the NFT contract to disallow.
    function disallowNFT(address nftContract) external onlyOwner {
        allowedNFTs[nftContract] = false;
    }

    /// @notice Lists an NFT for sale on the marketplace.
    /// @dev Caller must own the NFT and approve this contract to transfer it.
    /// @param nftContract The address of the NFT contract.
    /// @param tokenId The token ID of the NFT to list.
    /// @param price The sale price in wei. Must be greater than zero.
    /// @custom:error AlreadyListed Reverts if the NFT is already listed.
    /// @custom:error PriceCantBeZero Reverts if the price is zero.
    function listItem(address nftContract, uint256 tokenId, uint256 price)
        external whenNotPaused onlyAllowedNFTs(nftContract) {
            Listing memory listedItem = listings[nftContract][tokenId];
            // якщо seller НЕ address(0), то лістинг вже існує
            require(listedItem.seller == address(0), AlreadyListed(nftContract, tokenId));
            _listingProcess(nftContract, tokenId, price);


            emit ItemListed(msg.sender, nftContract, tokenId, price);
    }
    /// @notice Updates the price of an existing NFT listing.
    /// @dev Caller must be the original seller and the NFT must be approved.
    /// @param nftContract The address of the NFT contract.
    /// @param tokenId The token ID of the NFT.
    /// @param newPrice The new price in wei.
    /// @custom:error NotListed Reverts if the NFT is not listed.
    /// @custom:error PriceCantBeZero Reverts if the price is zero.
    function updateListingPrice(address nftContract, uint256 tokenId, uint256 newPrice)
        external whenNotPaused onlyAllowedNFTs(nftContract) {
        Listing memory listedItem = listings[nftContract][tokenId];
        require(listedItem.seller != address(0), NotListed(nftContract, tokenId));
        _listingProcess(nftContract, tokenId, newPrice);

        emit PriceUpdated(msg.sender, nftContract, tokenId, newPrice);
    }
    /// @notice Cancels an active listing for an NFT.
    /// @dev Only the seller who listed the NFT can cancel.
    /// @param nftContract The address of the NFT contract.
    /// @param tokenId The token ID of the NFT to list.
    /// @custom:error NotListed Reverts if the NFT is not listed.
    /// @custom:error NotSeller Reverts if the caller is not the seller.
    function cancelListing(address nftContract, uint256 tokenId)
        external whenNotPaused onlyAllowedNFTs(nftContract) {
        Listing memory listedItem = listings[nftContract][tokenId];
        require(listedItem.seller != address(0), NotListed(nftContract, tokenId));
        require(listedItem.seller == msg.sender, NotSeller());

        delete listings[nftContract][tokenId];
        emit ListingCancelled(msg.sender, nftContract, tokenId);
    }

    /// @notice Buys a listed item by paying the exact price.
    /// @dev Caller must send 'msg.value' equal to the listing price.
    /// @param nftContract The address of the NFT contract.
    /// @param tokenId The token ID of the NFT to list.
    /// @custom:error NotListed Reverts if the NFT is not listed.
    /// @custom:error InsufficientPayment Reverts if sent ETH is less than the price.
    /// @custom:error NotAnOwner Reverts if the seller no longer owns the NFT.
    /// @custom:error TransferFailed ETH transfer to seller fails.
    function buyItem(address nftContract, uint256 tokenId)
        external payable whenNotPaused onlyAllowedNFTs(nftContract) {
            Listing memory item = listings[nftContract][tokenId];
            if (item.price == 0) {
                revert NotListed(nftContract, tokenId);
            }
            
            if (msg.value != item.price) {
                revert InsufficientPayment();
            }

            IERC721 token = IERC721(nftContract);
            if (token.ownerOf(tokenId) != item.seller) {
                revert NotAnOwner();
            }
            _isApproved(nftContract, tokenId, item.seller);

            uint256 mpRevenue = (item.price * feeRate) / 1000;
            uint256 sellerEarnings = item.price - mpRevenue;

            token.safeTransferFrom(item.seller, msg.sender, tokenId);
            (bool success, ) = payable(item.seller).call{value: sellerEarnings}("");
            if (!success) {
                revert TransferFailed();
            }
            
            totalFees += mpRevenue;

            delete listings[nftContract][tokenId];

            emit ItemSold(msg.sender, nftContract, tokenId, msg.value);
    }
    /// @notice Pauses marketplace operations such as listing and buying.
    /// @dev Only callable by the contract owner.
    function pause() external onlyOwner {
        _pause();
    }
    /// @notice Resumes marketplace operations after being paused.
    /// @dev Only callable by the contract owner.
    function unpause() external onlyOwner {
        _unpause();
    }
}