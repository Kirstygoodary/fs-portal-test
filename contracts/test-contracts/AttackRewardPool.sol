// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../rewards/staking/RewardPool.sol";

contract AttackRewardPool {
    address public factoryAddress;

    function depleteRewardPool(
        RewardPool pool,
        address _factoryAddress
    ) external {
        factoryAddress = _factoryAddress;
        uint256 amount = pool.poolBalance();
        pool.fundStaker(msg.sender, amount - 1);
    }
}
