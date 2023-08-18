// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


abstract contract IPoolState {
    struct PoolState {
        uint256 poolId;
        string url;
        bytes poolDescription;
        address poolAddress;
        address rewardPoolAddress;
        uint256 totalTokensStaked;
        uint256 numberOfUsersStaked;
        uint256 maximumNumberOfStakers;
        uint256 waitingRoomOpenTime;
        uint256 raceStartTime;
        uint256 raceEndTime;
        uint256 claimTimeDate;
        uint256 poolInterestRateInBasisPoints;
        uint256 minimumStakePerUser;
        uint256 maximumStakePerUser;
        uint256 maximumInterestRateInBasisPoints;
        bool isPoolInitialized;
        bool isPoolDisabled;
    }
}