// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/HelloWorld.sol";

contract HelloWorldTest is Test {
    function test_greeting() public {
        HelloWorld helloWorld = new HelloWorld();
        assertEq(helloWorld.greeting(), "Hello World");
    }
}