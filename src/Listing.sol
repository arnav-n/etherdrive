// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./User.sol";

contract Listing {
    Car listedCar;
    User seller;
    uint256 minPrice; //bottom of price window, updates to the current minimum price whenever a bid is made
    uint256 maxPrice;
    // User buyer; NULL until listing is complete? useful for registration purposes
    // DateTime buyingWindow?
}