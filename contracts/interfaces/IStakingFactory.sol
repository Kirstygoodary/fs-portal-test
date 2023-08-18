// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IStakingFactory is ERC165 {
    function createNewRace(
        string memory _name,
        string memory _type,
        address _tokenAddress,
        address payable _rewardPool,
        uint256 maximumPoolSize,
        uint256 _months
    ) external virtual;
}
