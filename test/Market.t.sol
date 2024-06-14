// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Vm.sol";
import "forge-std/Test.sol";

import "../src/Market.sol";

contract MarketTest is Test {
    Market public mart;
    address alice = address(0x99);

    function setUp() public {
        mart = new Market();
        // deal(alice, 100 ether);
    }

    function test_registration() public {
        vm.startPrank(alice);
        mart.registerUser();
        vm.stopPrank();
        assertEq(mart.getUsers().length, 1);
    }
}