// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./User.sol";

contract Car{
    address curOwner;
    string make;
    string model;
    int year;
    int VIN;

    constructor(address _owner, string memory _make, string memory _model, int _year, int _vin) {
        curOwner = _owner;
        make = _make;
        model = _model;
        year = _year;
        VIN = _vin;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == curOwner, "only the owner can transfer ownership");
        curOwner = newOwner;
    }
}
