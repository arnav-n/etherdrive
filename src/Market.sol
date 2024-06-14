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

    event NewBid(address indexed bidder, uint256 amount);
    event ListingClosed(address indexed buyer, uint256 amount);

    function registerUser() public returns (uint256) {
        User storage newUser = users.push();
        newUser.addr = msg.sender;
        newUser.userID = users.length - 1; // Adjusted for zero-indexing
        return newUser.userID;
    }

    function addExistingVehicle(uint256 userId, Car memory c) public {
        User storage user = users[userId];
        user.ownedVehicles.push(c);
    }
    
    function addOwnedVehicle(uint256 userId, string memory _model, string memory _vin) public {
        User storage user = users[userId];
        require(user.addr == msg.sender, "Only the user can register a vehicle");

        Car memory newCar = Car(_model, _vin, msg.sender);
        user.ownedVehicles.push(newCar);
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

    function placeBid(uint256 listingId, uint256 buyerId) public payable {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing is not active");
        require(msg.value >= listing.minPrice, "Bid amount is less than minimum price");
        require(msg.value > listing.highestBid, "There already is a higher bid");

        // Refund the previous highest bidder
        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).transfer(listing.highestBid);
        }

        listing.highestBid = msg.value;
        listing.highestBidder = msg.sender;
        listing.buyerID = buyerId;

        emit NewBid(msg.sender, msg.value);
    }

    function closeListing(uint256 listingId) public {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Only the seller can close the listing");
        require(listing.isActive, "Listing is already closed");

        listing.isActive = false;

        if (listing.highestBidder != address(0)) {
            listing.buyer = listing.highestBidder;
            listing.listedCar.owner = listing.highestBidder;
            payable(listing.seller).transfer(listing.highestBid);
            emit ListingClosed(listing.highestBidder, listing.highestBid);
            addExistingVehicle(listing.buyerID, listing.listedCar);
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
}
