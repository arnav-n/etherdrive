// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./User.sol";

contract Car{
    User curOwner;
    string make;
    string model;
    int year;
    int VIN;
}
