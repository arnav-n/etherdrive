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
    //Test 1
    //Allows user to register within our account management system so that they can buy/sell
    function testRegistration() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        vm.stopPrank();
        //Since Alice is the only user registered, she should have userID of 0 
        //and there should only be 1 user in the system
        assertEq(userId, 0);
        assertEq(mart.getUsers().length, 1);
    }
    //Test 2
    //The user can add a car to their collection
    function testAddOwnedVehicle() public {
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        vm.stopPrank();
        //Since this is Alice's first vehicle that she is adding, there should only be 
        //one car in her collection which should correspond to the information that she 
        //passed in through the addOwnedVehicle func
        Market.Car[] memory cars = mart.getUserOwnedVehicles(0);
        assertEq(cars.length, 1);
        assertEq(cars[0].model, "Tesla Model S");
        assertEq(cars[0].vin, "5YJSA1E26MF123456");
        assertEq(cars[0].owner, alice);
    }
    //Test 3
    //The user can add an item to be sold within an expected price range
    function testCreateListing() public {
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        //After creating a listing, there should be exactly one listing in the market
        assertEq(mart.getListingsCount(), 1);

        //Retrieve the listing and verify its details to ensure it matches what Alice created
        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.seller, alice);
        assertEq(listing.minPrice, 1 ether);
        assertEq(listing.maxPrice, 2 ether);
        assertEq(listing.isActive, true);
        assertEq(listing.listedCar.model, "Tesla Model S");
    }
    //Test 4
    //A user can place a bid on a listing, and is recognized as the highest bidder if true
    function testPlaceBid() public {
        // Set up Bob's initial ETH balance
        vm.deal(bob, 3 ether);

        // Alice registers, adds a car, and creates a listing
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        // Bob registers and places a bid on Alice's listing
        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 1.5 ether}(0, bobID);
        vm.stopPrank();

        // Retrieve the listing and verify that Bob's bid is the highest
        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.highestBid, 1.5 ether);
        assertEq(listing.highestBidder, bob);
    }
    //Test 5
    //If the user attempts to bid at a price lower than the highest, their bid will be invalid
    //and they will not be able to buy the car
    function testFailedBid() public {
        // Set up Bob's initial ETH balance
        vm.deal(bob, 3 ether);

        // Alice registers, adds a car, and creates a listing with a minimum price of 4 ether
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 4 ether, 6 ether);
        vm.stopPrank();

        // Bob registers and attempts to place a bid of 3 ether, which is below the minimum price
        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.expectRevert("Bid amount is less than minimum price");
        vm.stopPrank();
    }
    //Test 6
    //The seller can close a listing after a successful bid which will recognize the highest bidder as the buyer
    function testCloseListing() public {
        // Set up Bob's initial ETH balance
        vm.deal(bob, 3 ether);

        // Alice registers, adds a car, and creates a listing
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();
        
        // Bob registers and places a bid on Alice's listing
        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 1.5 ether}(0, bobID);
        vm.stopPrank();

        // Alice closes the listing
        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();

        // Retrieve the listing and verify that it is no longer active and that Bob is the buyer
        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.isActive, false);
        assertEq(listing.buyer, bob);
        assertEq(listing.listedCar.owner, bob);
    }
    //Test 7
    //Only the seller can close a listing; an attempt by another user should fail
    function testFailedCloseListing() public {
        // Set up Bob's initial ETH balance
        vm.deal(bob, 3 ether);

         // Alice registers, adds a car, and creates a listing
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 2 ether);
        vm.stopPrank();

        // Bob registers and attempts to close Alice's listing which should fail as he is not the seller
        vm.startPrank(bob);
        mart.registerUser();
        mart.closeListing(0);
        vm.expectRevert("Only the seller can close the listing");
        vm.stopPrank();
    }

    //Test 8
    //A buyer can purchase a car from a seller and own the car
    //After buying the car, the buyer can then list the same car and become the seller
    function testFlipCar() public {
        // Set up Bob's initial ETH balance
        vm.deal(bob, 3 ether);

        // Alice registers, adds a car, and creates a listing
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 1 ether, 4 ether);
        vm.stopPrank();

        // Bob registers and places a bid on Alice's listing
        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.stopPrank();

        // Verify that the listing is active and Bob is the highest bidder
        Market.Listing memory listing = mart.getListing(0);
        assertEq(listing.isActive, true);
        assertEq(listing.highestBidder, bob);

        // Alice closes the listing
        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();

        // Verify that the listing is closed and Bob is the buyer
        listing = mart.getListing(0);
        assertEq(listing.isActive, false);
        assertEq(listing.buyer, bob);

        // Verify that Bob owns the car 
        Market.Car[] memory bobCars = mart.getUserOwnedVehicles(bobID);
        assertEq(bobCars.length, 1);
        assertEq(bobCars[0].vin, "5YJSA1E26MF123456");

        // Bob lists the car for sale again
        vm.startPrank(bob);
        mart.createListing(bobID, 0, 2 ether, 5 ether);
        vm.stopPrank();

        // Verify that the new listing by Bob exists
        assertEq(mart.getListingsCount(), 2);
        Market.Listing memory newListing = mart.getListing(1);
        assertEq(newListing.seller, bob);
        assertEq(newListing.minPrice, 2 ether);
        assertEq(newListing.maxPrice, 5 ether);
        assertEq(newListing.isActive, true);
        assertEq(newListing.listedCar.model, "Tesla Model S");
        assertEq(newListing.listedCar.vin, "5YJSA1E26MF123456");
        assertEq(newListing.listedCar.owner, bob);

        
    }
    //Test 9
    //Multiple users can place competing bids on the same listing within the same block, and the highest bid wins
    function testCompetingBids() public {
        // Set up Bob's and Charlie's initial ETH balances
        vm.deal(bob, 3 ether);
        vm.deal(charlie, 5 ether);

        // Alice registers, adds a car, and creates a listing
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 2 ether, 6 ether);
        vm.stopPrank();

        // Bob registers and places a bid on Alice's listing
        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.stopPrank();

        // Charlie registers and places a higher bid on the same listing
        vm.startPrank(charlie);
        uint256 charlieID = mart.registerUser();
        mart.placeBid{value: 5 ether}(0, charlieID);
        vm.stopPrank();

        // Alice closes the listing
        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();
        
        // Verify that Charlie, as the highest bidder, receives the car
        Market.Car[] memory charlieCars = mart.getUserOwnedVehicles(charlieID);
        assertEq(charlieCars.length, 1);
        assertEq(charlieCars[0].vin, "5YJSA1E26MF123456");
    }
    //Test 10
    function testRefunds() public {
        // Set up Bob's and Charlie's initial ETH balances
        vm.deal(bob, 3 ether);
        vm.deal(charlie, 5 ether);


        // Alice registers, adds a car, and creates a listing
        vm.startPrank(alice);
        mart.registerUser();
        mart.addOwnedVehicle(0, "Tesla Model S", "5YJSA1E26MF123456");
        mart.createListing(0, 0, 2 ether, 6 ether);
        vm.stopPrank();

        // Bob registers and places a bid on Alice's listing
        vm.startPrank(bob);
        uint256 bobID = mart.registerUser();
        mart.placeBid{value: 3 ether}(0, bobID);
        vm.stopPrank();

        // Charlie registers and places a higher bid on the same listing
        vm.startPrank(charlie);
        uint256 charlieID = mart.registerUser();
        mart.placeBid{value: 5 ether}(0, charlieID);
        vm.stopPrank();

        // Alice closes the listing
        vm.startPrank(alice);
        mart.closeListing(0);
        vm.stopPrank();
        
        // Verify that Bob was refunded his 3 ether after being outbid by Charlie
        assertEq(bob.balance, 3 ether);
    }
}
