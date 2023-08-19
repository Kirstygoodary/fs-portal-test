// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
@title Staking contract
@notice This contract is the staking contract.
@author MDRxTech
 */

abstract contract StakingStorage {
    /* ========== STATE VARIABLES ========== */
    /// Interest rate in basis points
    uint256 public interestRateInBps;

    /// Unbalanced Interest Rate
    uint256 public unbalancedInterestRatePerSecond;

    /// Maximum possible Interest Rate
    uint256 public maximumInterestRateInBasisPoints;

    /// The number of stakers
    uint256 public numberOfStakers;

    /// The maximum number of stakers allowed in the race
    uint256 public maximumNumberOfStakers;

    /// The Id for the staking pool
    uint256 public poolId;

    /// The description for the pool (string converted to bytes)
    bytes public poolDesc;

    /// TIME VARIABLES
    /// Time at which pool begins and the pool can begin receiving deposits
    uint256 public waitingRoomOpenDate;

    /// End of deposits and begining of the race
    uint256 public raceStartDate;

    /// Pit stops after the start of the race, and before the end of the race.
    uint256[] public pitStopDates;

    /// Total length of Race
    uint256 public totalVestingSecs;

    /// The end time after which users can unstake
    uint256 public raceEndDate;

    /// The time which a rewards may be claimed.
    uint256 public CLAIM_TIME_AFTER_ENDTIME;

    /// TOKEN STAKED VARIABLES
    /// Total amount of tokens staked
    uint256 totalAmountStaked;

    /// Minimum number of tokens that can be staked per user
    uint256 public MINIMUM_STAKING_PER_USER;

    /// Maximum staking per user that can be staked per user address
    uint256 public MAXIMUM_STAKING_PER_USER;

    /// The full value of the APR of the maximum pool size
    uint256 maximumReward;

    /// Holds the state of the pool, false when pool is ACTIVE, true when pool is closed.
    bool public isDisabled;

    bool public isInitialized;

    address public factoryAddress;
}
