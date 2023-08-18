// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../governance/GovernanceV1.sol";

contract GovernanceUpgrade is GovernanceV1 {
    string test;

    function setTest(string calldata _test) public {
        test = _test;
    }

    function getTest() public view returns (string memory) {
        return test;
    }
}
