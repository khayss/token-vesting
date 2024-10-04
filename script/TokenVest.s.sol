// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TokenVesting} from "../src/TokenVesting.sol";

contract DeployTokenVest is Script {
    address owner = 0xDaB8892C07FB4C362Dd99D9a2fBFf8B555D39Cb5;
    address token = 0x8c662626Aa5944b4b8206837892cFD45E1117D86;

    function setUp() external {}

    function run() external returns (address) {
        vm.startBroadcast();

        TokenVesting tokenVest = new TokenVesting(token, owner);

        vm.stopBroadcast();

        return address(tokenVest);
    }
}
