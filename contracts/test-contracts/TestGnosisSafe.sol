// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestGnosisSafe {
    uint private count;
    address public gnosisSafe;

    // Event that will emit when the counter changes
    event CountChanged(uint newCount);

    modifier onlyGnosisSafe(){
        require(msg.sender == gnosisSafe, "Only Gnosis Safe!");
        _;
    }

    constructor(address _gnosisSafe) {
        count = 0;
        gnosisSafe = _gnosisSafe;
    }

    // Function to get the current count
    function getCount() public view returns (uint) {
        return count;
    }

    // Function to increment the counter by 1
    function increment() onlyGnosisSafe public {
        count += 1;

        // Emit an event that the count has changed
        emit CountChanged(count);
    }

    // Function to decrement the counter by 1
    function decrement() onlyGnosisSafe public {
        require(count > 0, "Counter is already at zero, can't decrement further");

        count -= 1;

        // Emit an event that the count has changed
        emit CountChanged(count);
    }
}
