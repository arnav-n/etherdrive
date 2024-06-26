// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Market {
    struct Car {
        string model;
        string vin;
        address owner;
    }

    struct User {
        address addr;
        Car[] ownedVehicles;
        uint256 userID;
    }

    struct Listing {
        Car listedCar;
        address seller;
        uint256 minPrice;
        uint256 maxPrice;
        address buyer;
        bool isActive;
        uint256 highestBid;
        address highestBidder;
        uint256 buyerID;
    }

    User[] public users;
    Listing[] public listings;

    bool private locked;
    modifier noReentrancy() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function registerUser() public returns (uint256) {
        User storage newUser = users.push();
        newUser.addr = msg.sender;
        newUser.userID = users.length - 1; // Adjusted for zero-indexing
        return newUser.userID;
    }
    
    function addOwnedVehicle(uint256 userId, string memory _model, string memory _vin) public {
        User storage user = users[userId];
        require(user.addr == msg.sender, "Only the user can add a vehicle");

        Car memory newCar = Car(_model, _vin, msg.sender);
        user.ownedVehicles.push(newCar);
    }

    function addExistingVehicle(uint256 userId, Car memory c) public {
        User storage user = users[userId];
        user.ownedVehicles.push(c);
    }

    function createListing(uint256 userId, uint256 carIndex, uint256 _minPrice, uint256 _maxPrice) public {
        User storage user = users[userId];
        require(user.addr == msg.sender, "Only the user can create a listing");

        Car memory car = user.ownedVehicles[carIndex];

        // Remove the car from ownedVehicles
        user.ownedVehicles[carIndex] = user.ownedVehicles[user.ownedVehicles.length - 1];
        user.ownedVehicles.pop();

        Listing memory newListing = Listing({
            listedCar: car,
            seller: msg.sender,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            buyer: address(0),
            isActive: true,
            highestBid: 0,
            highestBidder: address(0),
            buyerID: 0
        });

        listings.push(newListing);
    }

    function placeBid(uint256 listingId, uint256 buyerId) public payable noReentrancy {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing is not active");
        require(msg.value >= listing.minPrice, "Bid amount is less than minimum price");
        require(msg.value > listing.highestBid, "There already is a higher bid");
        require(msg.value <= listing.maxPrice, "Higher than max price of vehiclle");

        // Update state before external call
        uint256 previousHighestBid = listing.highestBid;
        address previousHighestBidder = listing.highestBidder;

        listing.highestBid = msg.value;
        listing.highestBidder = msg.sender;
        listing.buyerID = buyerId;

        // Interactions
        if (previousHighestBidder != address(0)) {
            (bool success, ) = previousHighestBidder.call{value: previousHighestBid}("");
            require(success, "Refund failed");
        }
    }

    function closeListing(uint256 listingId) public noReentrancy {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Only the seller can close the listing");
        require(listing.isActive, "Listing is already closed");

        // Update state before external call
        listing.isActive = false;

        if (listing.highestBidder != address(0)) {
            listing.buyer = listing.highestBidder;
            listing.listedCar.owner = listing.highestBidder;
            uint256 highestBid = listing.highestBid;
            address seller = listing.seller;

            addExistingVehicle(listing.buyerID, listing.listedCar);

            listing.highestBid = 0;
            listing.highestBidder = address(0);

            // Interactions
            (bool success, ) = seller.call{value: highestBid}("");
            require(success, "Payment to seller failed");
        }
    }

    function getUserOwnedVehicles(uint256 userId) public view returns (Car[] memory) {
        return users[userId].ownedVehicles;
    }

    function getUsers() public view returns(User[] memory){
        return users;
    }

    function getListingsCount() public view returns (uint256) {
        return listings.length;
    }

    function getListing(uint256 index) public view returns (Listing memory) {
        require(index < listings.length, "Index out of bounds");
        return listings[index];
    }

    function getAllListings() public view returns (Listing[] memory) {
        return listings;
    }
}
