// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Listing.sol";
import "./Car.sol";

contract User{
    string name;
    address addr;
    Car[] ownedVehicles;

    function makeBid(Listing l, uint256 bidAmount) public{

    }
    
    function sellCar(Car c, uint256 minPrice, uint256 maxPrice) public returns(Listing){

    }
}
