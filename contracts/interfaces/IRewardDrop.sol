// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title RewardDrop interface
/// @notice RewardDrop facilitates the creation of and distribution of rewards
abstract contract IRewardDrop is ERC165 {
    /* ========== TYPE DECLARATIONS ========== */

    struct RewardDrop {
        string ref;
        uint256 claimStart;
        uint256 claimEnd;
        uint256 maxClaimPerWinner;
        uint256 maxWinners;
        uint256 totalClaimed;
        State state;
    }

    enum State {
        Active,
        Paused,
        Executed,
        Cancelled
    }

    /* ========== EVENTS ========== */

    event NewRewardDrop(
        uint256 indexed id,
        string ref,
        uint256 maxClaimPerWinner,
        uint256 maxWinners,
        uint256 claimStart,
        uint256 claimEnd
    );
    event RewardDropClaimed(uint256 indexed id, address indexed account);
    event RewardDropState(uint256 indexed id, State state);
    event RewardDropUpdated(
        uint256 indexed id,
        string ref,
        uint256 claimStart,
        uint256 claimEnd,
        uint256 maxClaimPerWinner,
        uint256 maxWinners
    );
    event ClaimStartDelay(uint256 startDelay);
    event MinimumClaimPeriod(uint256 minimumClaimPeriod);
    event MaximumClaimPerWinner(uint256 maxClaimPerWinner);
    event MaximumWinners(uint256 maximumWinners);

    /* ========== REVERT STATEMENTS ========== */

    error ClaimPeriodNotExpired(uint256 claimExpiry, uint256 current);
    error ExceedsMaxWinners(
        uint256 id,
        uint256 proposedWinners,
        uint256 maxWinners
    );
    error NonExistentID();
    error InsufficientBalance(uint256 balance, uint256 claimtotal);
    error WithdrawalExceedsExcess(uint256 withdrawal, uint256 excess);
    error InvalidRewardDropState(uint256 id, State state);
    error AirdropLive(uint256 id);
    error RewardDropEmpty(uint256 id);
    error MaximumWinnersExceeded(uint256 proposedCap, uint256 hardCap);
    error InvalidClaimStartTime(uint256 proposedStart, uint256 claimStartDelay);
    error InvalidClaimEndTime(uint256 proposedEnd, uint256 claimEndDelay);
    error ExceedsMaxClaimPerWinnerCap(
        uint256 proposedMaxClaim,
        uint256 maxClaimPerWinner
    );
    error ExceedsMaxWinnersCap(uint256 proposedMaxWinners, uint256 maxWinners);
    error Receive(string func, address caller, uint256 value);
    error Fallback(string func, address caller, uint256 value, bytes data);
    error ClaimStartDateIsZero(uint256 claimStartDate);
    error ClaimEndDateIsZero(uint256 claimEndDate);

    /* ========== FUNCTIONS ========== */

    function createRewardDrop(
        uint256 _claimStart,
        uint256 _claimEnd,
        uint256 _maxClaimPerWinner,
        uint256 _maxWinners,
        string calldata _description
    ) external virtual;

    function rewardDrop(
        uint256 _id,
        address[] calldata _winners
    ) external virtual;

    function withdraw(uint256 amount, address recepient) external virtual;

    function getRewardDrop(
        uint256 _id
    ) external view virtual returns (RewardDrop memory);

    function getRewardDropCount() external view virtual returns (uint256);

    function getPaginatedRewardDrops(
        uint16 _pageLength,
        uint16 _page,
        uint8 _direction
    ) external view virtual returns (RewardDrop[] memory);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;

    function pauseRewardDrop(uint256 _id) external virtual;

    function unpauseRewardDrop(uint256 _id) external virtual;

    function cancelRewardDrop(uint256 _id) external virtual;

    function setClaimStartDelay(uint256 _claimStartDelay) external virtual;

    function setMinimumClaimPeriod(
        uint256 _minimumClaimPeriod
    ) external virtual;

    function setMaximumClaimPerWinner(
        uint256 _maximumClaimPerWinner
    ) external virtual;

    function setMaximumWinners(uint256 _maximumWinners) external virtual;
}
