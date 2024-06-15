## EtherDrive

**An on-chain car marketplace**

## Usage
To run tests, run `forge test`. 

A user can register in the system by calling registerUser(), and can then perform actions to manage their inventory, view all listed cars, create a listing of their own, or place a bid for a listing. After registering, the user will be assigned a User ID which they can use to place bids or create listings. All functionality happens within the Market.sol smart contract. 

## Documentation
`registerUser()`

**Parameters**: None

**Return Type**: `uint256`

**Description**: Registers the current user in the Market, returning their User ID number. 

`createListing(uint256 userId, uint256 carIndex, uint256 _minPrice, uint256 _maxPrice)`

**Parameters**: current user's ID number, index of the car they want to sell in their ownedVehicles array, and a price range

**Return Type**: None

**Description**: Creates a for-sale listing for the given car, with the specified price range. 

`placeBid(uint256 listingId, uint256 buyerId)`

**Parameters**: listing ID for which to place a bid, and current user's user ID

**Return Type**: None

**Description**: Call by using `market.placeBid{value: X ether}(listingID, userID);`

**Special Notes**: payable function, care is necessary to prevent reentrancy exploits


`closeListing(uint256 listingId)`

**Parameters**: listing ID to close

**Return Type**: None

**Description**: The user can call this function to close a listing they have posted, signifying that the sale period has ended. The car will then be sold to the highest bidder at this time. 


`addExistingVehicle(uint256 userId, Car memory c)`

`addOwnedVehicle(uint256 userId, string memory _model, string memory _vin)`

**Parameters**: user ID to add the car to, as well as either a Car object or information for a Car

**Return Type**: None

**Description**: These functions allow you to add a car to your inventory, but differ in their parameters. 


`getUserOwnedVehicles(uint256 userId)`
**Parameters**: User ID to fetch owned vehicles

**Return Type**: `Car[]`

**Description**: Simple getter function to fetch a user's owned vehicles


`getUsers()`
**Parameters**: None

**Return Type**: `User []`

**Description**: Getter function to fetch all users


`getListingsCount()`
**Parameters**: None

**Return Type**: `uint256`

**Description**: Getter function to fetch length of global listings array


`getListing(uint256 index)`
**Parameters**: Index of the listing in the global listing array

**Return Type**: `Listing`

**Description**: Getter function to fetch a single given listing


`getAllListings()`
**Parameters**: None

**Return Type**: `Listing []`

**Description**: Getter function to fetch all listings


