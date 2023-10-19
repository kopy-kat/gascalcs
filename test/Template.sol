// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

function func1(uint256 a) pure returns (uint256) {
    return a++;
}

function func2(uint256 a) pure returns (uint256) {
    return ++a;
}

contract Template is Test {
    function testGas() public {
        uint256 gasCheck = gasleft();
        uint256 return1 = func1(2);
        gasCheck = gasCheck - gasleft();

        uint256 gasCheck256 = gasleft();
        uint256 return2 = func2(2);
        gasCheck256 = gasCheck256 - gasleft();

        console.log("gasFunc1: %s", gasCheck);
        console.log("gasFunc2: %s", gasCheck256);
    }
}
