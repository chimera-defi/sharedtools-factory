// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "hardhat/console.sol";


contract Greeter {
    string public greeting;
    event GreeterError();

    constructor(string memory _greeting) {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }

    // function throwError() external pure {
    //     emit GreeterError();
    //     revert;
    // }
}
