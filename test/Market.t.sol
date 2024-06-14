// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Market.sol";

contract MarketTest is Test {
    Market public mart;
    address alice = address(0x99);
    address bob = address(0x100);
    address charlie = address(0x101);

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
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 1.5 ether}(0, bobID);
        vm.stopPrank();

        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.highestBid, 1.5 ether);
        assertEq(listing.highestBidder, bob);
    }

    function testFailedBid() public {
        vm.deal(bob, 3 ether);
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 4 ether, 6 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.expectRevert("Bid amount is less than minimum price");
        vm.stopPrank();
    }

    function testCloseListing() public {
        vm.deal(bob, 3 ether);
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 1.5 ether}(0, bobID);
        vm.stopPrank();

        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();

        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.isActive, false);
        assertEq(listing.buyer, bob);
        assertEq(listing.listedCar.owner, bob);
    }

    function testFailedCloseListing() public {
        vm.deal(bob, 3 ether);
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        mart.registerUser();
        mart.closeListing(0);
        vm.expectRevert("Only the seller can close the listing");
        vm.stopPrank();
    }

    function testFlipCar() public {
        vm.deal(bob, 3 ether);
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 4 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.stopPrank();

        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.isActive, true);
        assertEq(listing.highestBidder, bob);

        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();

        listing = mart.getListing(0);
        assertEq(listing.isActive, false);
        assertEq(listing.buyer, bob);

        Market.Car[] memory bobCars = mart.getUserOwnedVehicles(bobID);
        assertEq(bobCars.length, 1);
        assertEq(bobCars[0].vin, "5YJSA1E26MF123456");
    }

    function testCompetingBids() public {
        vm.deal(bob, 3 ether);
        vm.deal(charlie, 5 ether);

        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 2 ether, 6 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.stopPrank();

        vm.startPrank(charlie);
        uint256 charlieID = mart.registerUser();
        mart.placeBid{value: 5 ether}(0, charlieID);
        vm.stopPrank();

        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();
        
        // assert that charlie received the car
        Market.Car[] memory charlieCars = mart.getUserOwnedVehicles(charlieID);
        assertEq(charlieCars.length, 1);
        assertEq(charlieCars[0].vin, "5YJSA1E26MF123456");
    }

    function testRefunds() public {
        vm.deal(bob, 3 ether);
        vm.deal(charlie, 5 ether);

        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 2 ether, 6 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.stopPrank();

        vm.startPrank(charlie);
        uint256 charlieID = mart.registerUser();
        mart.placeBid{value: 5 ether}(0, charlieID);
        vm.stopPrank();

        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();
        
        // assert that bob was refunded
        assertEq(bob.balance, 3 ether);
    }
}
