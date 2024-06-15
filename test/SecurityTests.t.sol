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

    // Test 1
    // Test against reentrancy attack on placeBid() function
    // One of 2 functions that have reentrancy risk, we used a reentrancy lock to prevent this
    function testReentrancyOnPlaceBid() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        mart.addOwnedVehicle(userId, "Model X", "VIN123");

        // Create listing
        mart.createListing(userId, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.deal(bob, 2 ether);
        vm.startPrank(bob);
        // Place initial bid
        (bool success1, ) = address(mart).call{value: 1.1 ether}(abi.encodeWithSignature("placeBid(uint256)", 0));
        require(success1, "Initial bid failed");

        // Try to reenter the placeBid function
        (bool success2, ) = address(mart).call{value: 1.2 ether}(abi.encodeWithSignature("placeBid(uint256)", 0));
        require(!success2, "Reentrancy attack should be prevented");
        vm.stopPrank();
    }

    // Test 2
    // Test against reentrancy attack on closeListing() function
    // Again we used a reentrancy lock in this function to prevent reentrancy
    function testReentrancyOnCloseListing() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        mart.addOwnedVehicle(userId, "Model S", "VIN456");

        // Create listing
        mart.createListing(userId, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.deal(bob, 2 ether);
        vm.startPrank(bob);
        // Place bid
        (bool success1, ) = address(mart).call{value: 1.5 ether}(abi.encodeWithSignature("placeBid(uint256)", 0));
        require(success1, "Bid failed");
        vm.stopPrank();

        vm.startPrank(alice);
        // Close listing (reentrancy)
        (bool success2, ) = address(mart).call(abi.encodeWithSignature("closeListing(uint256)", 0));
        require(success2, "Listing should be closed without reentrancy attack");
        vm.stopPrank();
    }

    // Test 3
    // Test to ensure that only the owner of a vehicle can list it
    // Otherwise people can take the ETH after selling a vehicle that is not owned by them
    function testAddVehicleOnlyByOwner() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        vm.stopPrank();

        vm.startPrank(bob);
        // Bob tries to add Alice's vehicle, and we save the result in a bool
        (bool success, ) = address(mart).call(abi.encodeWithSignature("addOwnedVehicle(uint256,string,string)", userId, "Model 3", "VIN789"));
        require(!success, "Only the owner should be able to add a vehicle");
        vm.stopPrank();
    }

    // Test 4
    // Only the owner of a vehicle can create a listing for that vehicle
    // Otherwise people can take the ETH after selling a vehicle that is not owned by them
    function testCreateListingOnlyByOwner() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        mart.addOwnedVehicle(userId, "Model Y", "VIN101");
        vm.stopPrank();

        vm.startPrank(bob);
        // Bob tries to create a listing with Alice's vehicle
        (bool success, ) = address(mart).call(abi.encodeWithSignature("createListing(uint256,uint256,uint256,uint256)", userId, 0, 1 ether, 2 ether));
        require(!success, "Only the owner should be able to create a listing");
        vm.stopPrank();
    }

    // Test 5
    // Test against placing a bid that is below the minimum price
    // This could cause people to place a bid under min price and potentially they can win the auction
    function testPlaceBidBelowMinPrice() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        mart.addOwnedVehicle(userId, "Model X", "VIN123");

        // Create listing
        mart.createListing(userId, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        (bool success, ) = address(mart).call{value: 0.5 ether}(abi.encodeWithSignature("placeBid(uint256)", 0));
        require(!success, "Bid amount should be above the minimum price");
        vm.stopPrank();
    }

    // Test 6
    // Ensure that bids can only be placed if they are greater than the current bid
    // Otherwise a malicious user could potentially make a minimum price bid right before the bid window expires and potentially win the auction
    function testPlaceBidHigherThanCurrent() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        mart.addOwnedVehicle(userId, "Model X", "VIN123");

        // Create listing
        mart.createListing(userId, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.deal(bob, 2 ether);
        vm.startPrank(bob);
        // Place initial bid
        (bool success1, ) = address(mart).call{value: 1.1 ether}(abi.encodeWithSignature("placeBid(uint256)", 0));
        require(success1, "Initial bid failed");

        (bool success2, ) = address(mart).call{value: 1 ether}(abi.encodeWithSignature("placeBid(uint256)", 0));
        require(!success2, "Bid should be higher than the current highest bid");
        vm.stopPrank();
    }

    // Test 7
    // Test that we only allow sellers, not buyers, to close listings
    // If we allow a buyer to be able to close the listing, they can potentially place a minimum price bid as soon as a listing is created, close it, and get the car for a minimum price
    function testCloseListingOnlyBySeller() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        mart.addOwnedVehicle(userId, "Model X", "VIN123");

        // Create listing
        mart.createListing(userId, 0, 1 ether, 2 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        (bool success, ) = address(mart).call(abi.encodeWithSignature("closeListing(uint256)", 0));
        require(!success, "Only the seller should be able to close the listing");
        vm.stopPrank();
    }

    // Test 8
    // Prevent unauthorized users to access vehicles
    // This can potentially leak information about vehicles, such as title/registration/etc., to users who are not the owner of a vehicle
    function testPreventUnauthorizedAccessToUserVehicles() public {
        vm.startPrank(alice);
        uint256 userId = mart.registerUser();
        mart.addOwnedVehicle(userId, "Model X", "VIN123");
        vm.stopPrank();

        vm.startPrank(bob);
        (bool success, ) = address(mart).call(abi.encodeWithSignature("getUserOwnedVehicles(uint256)", userId + 1));
        require(!success, "Unauthorized access to user vehicles should be prevented");
        vm.stopPrank();
    }

    // Test 9
    // Test against invalid listing index
    // Ensure that users cannot get listings that don't exist
    function testInvalidListingIndex() public {
        (bool success, ) = address(mart).call(abi.encodeWithSignature("getListing(uint256)", 999));
        require(!success, "Accessing invalid listing index should fail");
    }

    // Test 10
    // Test against invalid user index
    // Ensure that users cannot get information about other users' vehicles if they are not the owners
    function testInvalidUserIndex() public {
        (bool success, ) = address(mart).call(abi.encodeWithSignature("getUserOwnedVehicles(uint256)", 999));
        require(!success, "Accessing invalid user index should fail");
    }
}