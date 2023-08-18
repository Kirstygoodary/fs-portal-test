// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TestStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestContractV1 is TestStorage, Ownable {
    event NewValue(uint256 newValue);

    function increaseValue(uint256 _newValue) public onlyOwner {
        value += _newValue;
        emit NewValue(_newValue);
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}
