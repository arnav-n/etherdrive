// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct User{
    string name;
    address addr;
    Car[] owned_vehicles;
}

struct Car{
    User cur_owner;
    string make;
    string model;
    int year;
    int VIN;
}