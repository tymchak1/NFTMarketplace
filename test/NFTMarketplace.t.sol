// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "../src/NFTMarketplace.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor(address initialOwner)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function safeMint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }
}

contract NFTMarketplaceTest is Test {
    NFTMarketplace marketplace;
    TestNFT testNFT;

    function setUp() public {
        marketplace = new NFTMarketplace();
        testNFT = new TestNFT(address(this));
    }


    function testListItemSuccess() external {
    address user = vm.addr(1);
    uint256 tokenId = testNFT.safeMint(user);

    vm.prank(user);
    testNFT.approve(address(marketplace), tokenId);

    uint256 price = 1 ether;

    vm.expectEmit(true, true, true, true);
    emit NFTMarketplace.ItemListed(user, address(testNFT), tokenId, price);

    vm.prank(user);
    marketplace.listItem(address(testNFT), tokenId, price);

    NFTMarketplace.Listing memory listing = marketplace.getListing(address(testNFT), tokenId);
    assertEq(listing.seller, user);
    assertEq(listing.price, price);
}
}