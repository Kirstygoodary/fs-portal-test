// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 100000000 * 10**decimals());
    }

    function mint(uint256 amount) external {
        require(amount > 0, "great than 0");
        _mint(msg.sender, amount);
    }
}
