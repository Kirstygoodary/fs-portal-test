// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IPoolState.sol";

abstract contract IStaking is IPoolState, ERC165 {
    /* ========== EVENTS ========== */

    event InitializedPool(
        uint256 waitingRoomOpenTime,
        uint256 raceStartTime,
        uint256 interestRateInBps,
        uint256 minimumStakingPerUser,
        uint256 maximumStakingPerUser,
        uint256 maximumReward,
        uint256 raceEndTime,
        uint256 claimTimeAfterEndTime,
        uint256 maximumNumberOfStakers,
        uint256[] pitStopDates,
        bool isInitialized
    );

    event Staked(
        address indexed staker,
        uint256 indexed amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event StakedFor(
        address indexed benefactor,
        address beneficiary,
        uint256 indexed amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event Unstaked(
        address indexed staker,
        uint256 indexed amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event ClaimedRewards(
        address indexed staker,
        uint256 indexed amount,
        uint256 totalBalance
    );

    event PoolDisabled(address caller, address pool, bool isDisabled);

    event StakersCountChanged(
        uint256 previousCount,
        uint256 newCount,
        address indexed caller
    );

    event MaximumInterestRateChanged(
        uint256 previousRate,
        uint256 currentRate,
        address indexed caller
    );

    /* ========== REVERT STATEMENTS ========== */

    error Staking__InsufficientTokens();
    error Staking__ZeroAmountNotAllowed();
    error Staking__PoolLimitReached();
    error Staking__BelowMinimumStake();
    error Staking__AboveMaximumStakePerUser();
    error Staking__AboveMaximumStake();
    error Staking__DepositPeriodHasPassed();
    error Staking__NoClaimableRewardsLeftInThePreviousPeriod();
    error Staking__NoClaimableRewards();
    error Staking__CannotRolloverWithdrawInstead();
    error Staking__StillInWaitingPeriod();
    error Staking__WaitTillRaceIsOver();
    error Staking__WaitForDepositToBegin();
    error Staking__AccessForbidden();
    error Staking__MaximumStakersExceeded();

    /* ========== FUNCTIONS ========== */

    function deposit(uint256 amount) external virtual;

    function viewUserBalance(
        address account
    ) external view virtual returns (uint256);

    function viewTotalRewards() external view virtual returns (uint256);

    function viewTotalRewardsAdmin(
        address account
    ) external view virtual returns (uint256);

    function payClaimableReward() external virtual;

    function unstake() external virtual;

    function totalStakers() external view virtual returns (uint256);

    function totalStaked() external view virtual returns (uint256);

    function printPitStopDates()
        external
        view
        virtual
        returns (uint256[] memory);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;

    function disablePool() external virtual;

    function getPastCheckpoint(
        address account,
        uint256 blockNumber
    ) external view virtual returns (uint256);

    function hasPoolExpired() external view virtual returns (bool);

    function getRaceStartDate() external virtual returns(uint256);

    function getWaitingRoomOpenDate() external virtual returns(uint256);

    function readPoolState()
        external view
        virtual
        returns (PoolState memory);

    function initializePoolValues(
        string memory _url,
        uint256 _interestInBasisPoints,
        uint256 _waitingRoomOpenDate,
        uint256 _raceStartDate,
        uint256 _raceEndDate,
        uint256 _minStakingPerUser,
        uint256 _maxStakingPerUser,
        uint256 _claimTimeAfterEndtime,
        uint256[] memory _pitStopDates,
        uint256 _numberOfStakers,
        bool poolInitialized
    ) external virtual;

    function isValidPoolState() external virtual returns(bool);
    function getDisabledStatus() external virtual returns(bool);
}
