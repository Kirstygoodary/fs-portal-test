// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title RewardPool interface
/// @notice RewardPool facilitates the transfer of stakin rewards
abstract contract IRewardPool is ERC165 {
    function fundStaker(address to, uint256 amount) external virtual;

    function withdraw(uint256 amount, address recepient) external virtual;
}
