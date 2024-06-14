// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Market.sol";

contract MarketTest is Test {
    Market public mart;
    address alice = address(0x99);
    address bob = address(0x100);

    function setUp() public {
        mart = new Market();
    }

    function testRegistration() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        vm.stopPrank();
        assertEq(userId, 0);
        assertEq(mart.getUsers().length, 1);
    }

    function testAddOwnedVehicle() public {
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        vm.stopPrank();
        
        Market.Car[] memory cars = mart.getUserOwnedVehicles(0);
        assertEq(cars.length, 1);
        assertEq(cars[0].model, "Tesla Model S");
        assertEq(cars[0].vin, "5YJSA1E26MF123456");
        assertEq(cars[0].owner, alice);
    }

    function testCreateListing() public {
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        assertEq(mart.getListingsCount(), 1);
        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.seller, alice);
        assertEq(listing.minPrice, 1 ether);
        assertEq(listing.maxPrice, 2 ether);
        assertEq(listing.isActive, true);
        assertEq(listing.listedCar.model, "Tesla Model S");
    }

    function testPlaceBid() public {
        vm.deal(bob, 3 ether);
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        mart.placeBid{value: 1.5 ether}(0);
        vm.stopPrank();

        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.highestBid, 1.5 ether);
        assertEq(listing.highestBidder, bob);
    }

    function testCloseListing() public {
        vm.deal(bob, 3 ether);
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        mart.placeBid{value: 1.5 ether}(0);
        vm.stopPrank();

        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();

        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.isActive, false);
        assertEq(listing.buyer, bob);
        assertEq(listing.listedCar.owner, bob);
    }
}
