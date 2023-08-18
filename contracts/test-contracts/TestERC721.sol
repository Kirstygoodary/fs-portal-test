// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC721 is ERC1155 {
    uint256 id;
    string public name;
    string public symbol;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }

    function mint(uint256 _amount) public {
        _mint(msg.sender, id, _amount, "");
        id++;
    }
}
