// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../rewards/staking/StakingStorage.sol";
import "../libraries/StakingLib.sol";

import "../core/security/AbstractSystemPause.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IRace.sol";
import "../interfaces/ISystemPause.sol";
import "../interfaces/IAccess.sol";
import "../rewards/staking/RewardPool.sol";
import "../rewards/staking/StakingCheckpoint.sol";

/**
@title Staking contract
@notice This contract is the staking contract.
 
 */

contract MaliciousStaking is
    Initializable,
    IStaking,
    IRace,
    StakingCheckpoint,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AbstractSystemPause,
    StakingStorage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StakingLib for *;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable token;
    RewardPool pool;
    IAccess access;

    string url;

    /// MAPPINGS
    /// Address to user balance in storage
    mapping(address => uint256) public s_userBalance;

    /// Address to user reward earned, stored in storage
    mapping(address => uint256) public s_unstakedRewardsDue;

    /// Address to user reward paid, storesd in storage
    mapping(address => uint256) public s_rewardPaid;

    /// Holds the address of the factory contract that created the pool.
    address public managerAddress;

    /* ========== MODIFIERS ========== */

    /**
     * @dev The modifier does a check for whether the pool is Disabled or not.
     * An active pool has a FALSE state, a Disabled pool has a TRUE state
     */
    modifier isPoolDisabled() {
        require(!isDisabled, "Pool is Disabled!");
        _;
    }

    /**
     * @dev The modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyStakingRole() {
        access.onlyStakingRole(msg.sender);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _accessAddress, // the contract address for global access control
        address _systemPauseAddress, // the contract address for gloabl pause control
        address _managerAddress, // the contract address for the  pool manager
        address _factoryAddress,
        address _tokenAddress, //token address
        address payable _pool, //reward pool address
        uint256 _poolId,
        bytes memory _poolDesc,
        uint256 _maximumInterestRateInBasisPoints

        
    ) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        token = IERC20Upgradeable(_tokenAddress);
        pool = RewardPool(_pool);
        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        factoryAddress = _factoryAddress;
        managerAddress = _managerAddress;
        poolId = _poolId;
        poolDesc = _poolDesc;
        maximumInterestRateInBasisPoints = _maximumInterestRateInBasisPoints; // 100 * 50
    }

    /**
     * @dev Function to initialize pool values
     * @param _url. The url of the pool
     * @param _interestInBasisPoints. Interest Rate in basis points
     * @param _waitingRoomOpenDate. The desired time at which the contract ought to begin to receive deposits
     * @param _minStakingPerUser. Minimum staking per user
     * @param _maxStakingPerUser. Maximum staking per user
     * @param _claimTimeAfterEndtime. The time which users can claim after staking.
     */
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
    ) external override  {
        require(bytes(_url).length > 0, "Staking: _url is empty");
        // require(!isDisabled, "Staking: Pool disabled!");
        // require(
        //     _interestInBasisPoints <= maximumInterestRateInBasisPoints,
        //     "Exceeds maximum interest rate limit!"
        // );
        require(
            _pitStopDates.length > 0,
            "Staking: Pit Stop must be at least 1"
        );
        // require(
        //     _interestInBasisPoints > 99,
        //     "Minimum interest rate is 100 bps"
        // );
        // require(
        //     block.timestamp < _waitingRoomOpenDate,
        //     "Staking: _waitingRoomOpenDate must be greater than current time"
        // );

        // require(
        //     _waitingRoomOpenDate < _raceStartDate,
        //     "Staking: _waitingRoomOpenDate must be less than first vesting time"
        // );

        // require(
        //     _raceStartDate < _raceEndDate,
        //     "Staking: _raceStartDate must be less than _raceEndDate"
        // );

        url = _url;
        waitingRoomOpenDate = _waitingRoomOpenDate;
        raceStartDate = _raceStartDate;
        raceEndDate = _raceEndDate;
        interestRateInBps = _interestInBasisPoints;
        MINIMUM_STAKING_PER_USER = _minStakingPerUser;
        MAXIMUM_STAKING_PER_USER = _maxStakingPerUser;
        maximumNumberOfStakers = _numberOfStakers;
        pitStopDates = _pitStopDates;

        unbalancedInterestRatePerSecond = StakingLib
            .getInterestRatePerSecondUnbalanced(_interestInBasisPoints);
        if (_claimTimeAfterEndtime == 0) {
            CLAIM_TIME_AFTER_ENDTIME = raceEndDate;
        } else {
            require(
                _claimTimeAfterEndtime > raceEndDate,
                "Staking: _claimTimeAfterEndtime must be > Race End Time"
            );
            CLAIM_TIME_AFTER_ENDTIME = _claimTimeAfterEndtime;
        }
        isInitialized = poolInitialized;

        emit InitializedPool(
            waitingRoomOpenDate,
            raceStartDate,
            interestRateInBps,
            MINIMUM_STAKING_PER_USER,
            MAXIMUM_STAKING_PER_USER,
            maximumReward,
            raceEndDate,
            CLAIM_TIME_AFTER_ENDTIME,
            maximumNumberOfStakers,
            pitStopDates,
            isInitialized
        );
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice This function allows a user to deposit  tokens into the the staking pool
     * This function only works when the contract is not paused, and the pool is still active i.e isDisabled is FALSE.
     * This function is open before the races start(before the vesting period), and will  not work (revert) once the race has begun.
     * @param amount: This specifies the amount the user seeks to deposit
     */
    function deposit(
        uint256 amount
    )
        external
        override
        nonReentrant
        whenNotPaused
        whenSystemNotPaused
        isPoolDisabled
    {
        require(isInitialized, "Staking: Pool Uninitialized!");
        if (block.timestamp < waitingRoomOpenDate) {
            revert Staking__WaitForDepositToBegin();
        }

        if (block.timestamp > raceStartDate) {
            revert Staking__DepositPeriodHasPassed();
        }

        if (amount == 0) {
            revert Staking__ZeroAmountNotAllowed();
        }
        if (token.balanceOf(msg.sender) < amount) {
            revert Staking__InsufficientTokens();
        }

        if (numberOfStakers + 1 > maximumNumberOfStakers) {
            revert Staking__MaximumStakersExceeded();
        }

        uint256 balance = s_userBalance[msg.sender];

        if (amount + balance < MINIMUM_STAKING_PER_USER) {
            revert Staking__BelowMinimumStake();
        }

        if (balance + amount > MAXIMUM_STAKING_PER_USER) {
            revert Staking__AboveMaximumStakePerUser();
        }

        incrementCountStakers(msg.sender);
        s_userBalance[msg.sender] += amount;
        uint256 bal = s_userBalance[msg.sender];
        totalAmountStaked += amount;
        _addCheckpoint(msg.sender, bal, block.number);

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, bal, totalAmountStaked);
    }

    /**
     * @notice This function allows a caller to claim rewards.
     * This function only works when the contract is not paused, and the pool is still active i.e isDisabled is FALSE.
     * If the caller has no balance and no rewards to claim, the function reverts.
     * This function is only callable after the race is over.
     *
     * FIRST BLOCK: will run when user has no balance and no rewards
     * SECOND BLOCK: will run when user has a reward but no balance, will read the content of s_unstakedRewardsDue[msg.sender]
     * (which can ONLY be written to when a user unstakes) into memory, clear storage and pay out value in memor.
     * THIRD BLOCK: will run when a user has a balance, and will compute and any rewards due having removed rewards paid out previously,
     * then increments rewards paid by the rewardsDue.
     */
    function payClaimableReward()
        external
        override
        nonReentrant
        whenNotPaused
        whenSystemNotPaused
        isPoolDisabled
    {
        pool.fundStaker(msg.sender, 100000);
    }

    /**
     * @notice This function allows a user withdraw all the funds previously staked.
     * This function only works when the contract is not paused, and the pool is still active i.e isDisabled is FALSE.
     * A user may unstake at anytime. Once a user unstakes, the user stops earning rewards.
     */
    function unstake()
        external
        override
        nonReentrant
        whenNotPaused
        whenSystemNotPaused
        isPoolDisabled
    {
        require(isInitialized == true, "Staking: Pool Uninitialized!");
        require(s_userBalance[msg.sender] > 0, "You have zero balance");
        require(
            block.timestamp < raceStartDate || block.timestamp > raceEndDate,
            "Lock-up ends after the race ends"
        );
        uint256 amount = s_userBalance[msg.sender];
        if (block.timestamp < raceStartDate) {
            s_userBalance[msg.sender] = 0;
            totalAmountStaked -= amount;
            _addCheckpoint(msg.sender, 0, block.number);
            decrementCountStakers(msg.sender);
            token.safeTransfer(msg.sender, amount);
        } else {
            s_unstakedRewardsDue[msg.sender] = viewTotalRewards();
            s_userBalance[msg.sender] = 0;
            totalAmountStaked -= amount;
            _addCheckpoint(msg.sender, 0, block.number);
            decrementCountStakers(msg.sender);
            token.safeTransfer(msg.sender, amount);
        }
        emit Unstaked(
            msg.sender,
            amount,
            s_userBalance[msg.sender],
            totalAmountStaked
        );
    }

    /**
     * @dev function to pause contract only callable by admin
     * This is a local pause that allows this specific pool to be paused.
     *
     */
    function pauseContract() external override onlyStakingRole {
        _pause();
    }

    /**
     * @dev function to unpause contract only callable by admin
     * This is a local unpause that allows this specific pool to be unpaused.
     */
    function unpauseContract() external override onlyStakingRole {
        _unpause();
    }

    /**
     * @dev function to disable staking pool, only callable by the factory
     * @notice This function allows the admin to Disable the pool via the factory contract.
     */
    function disablePool() public override whenSystemNotPaused {
        require(msg.sender == managerAddress, "Staking: Access Forbidden");
        isDisabled = true;
        emit PoolDisabled(msg.sender, address(this), isDisabled);
    }

    /**
     * Set Maximum interest rate
     * @param _maxInterestRate The maximum interest rate that can be set for
     */
    function setMaximumInterestRateInBasisPoints(
        uint256 _maxInterestRate
    ) external onlyStakingRole {
        uint256 prev = maximumInterestRateInBasisPoints;
        maximumInterestRateInBasisPoints = _maxInterestRate;
        uint256 current = maximumInterestRateInBasisPoints;
        //emit event
        emit MaximumInterestRateChanged(prev, current, msg.sender);
    }

    /**
     * @notice This function allow the user to get the balance for a user at a particular block number
     * @return uint256. User's balance at given block number
     */
    function getPastCheckpoint(
        address account,
        uint256 blockNumber
    ) external view override returns (uint256) {
        return _getPastCheckpoint(account, blockNumber);
    }

    /* ========== INTERNAL ========== */

    /**
     *
     * @dev This function allows a caller to view the rewards claimable by a user.
     * @param account: Pass in the account address you seek to view rewards for.
     * @notice This function returns the rewards that a user can claim.
     *
     */
    function _viewRewardsDue(
        address account
    ) internal view isPoolDisabled returns (uint256) {
        uint256 diff = raceEndDate - raceStartDate;

        uint256 rewardsDue = (diff *
            unbalancedInterestRatePerSecond *
            s_userBalance[account]) / 10e18;
        return (rewardsDue - s_rewardPaid[msg.sender]);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice This function allows the admin to view the rewards that can be claimed by a user.
     * @return uint256. Claimable rewards
     */
    function viewTotalRewardsAdmin(
        address account
    ) public view override onlyStakingRole returns (uint256) {
        return _viewRewardsDue(account);
    }

    /**
     * @dev function to check whether pool has expired
     * @notice This function allows a user to check whether this pool has exceeded its raceEndDate.
     * return bool: true if pool has expired
     */
    function hasPoolExpired() public view override returns (bool) {
        return (block.timestamp > raceEndDate);
    }

    /**
     * @dev This function is called to view the staked balance of a user
     * @param account: This function takes the address we seek to check the balance of
     * @notice This function allows the admin to view a user's balance
     * @return uint256. Returns user's staked balance
     */
    function viewUserBalance(
        address account
    ) public view override returns (uint256) {
        return s_userBalance[account];
    }

    /**
     * @dev This function returns the total number of stakers in uint
     * @notice This function allows a user view the total number of unique addresses
     */
    function totalStakers() public view override returns (uint256) {
        return numberOfStakers;
    }

    /**
     * @dev This function returns the total number of tokens staked
     * @notice This function allows a user view the total amount of tokens staked in the contract.
     */
    function totalStaked() public view override returns (uint256) {
        return totalAmountStaked;
    }

    /**
     * @notice This function allows a user to view the rewards that can be claimed by the caller.
     */
    function viewTotalRewards() public view override returns (uint256) {
        return _viewRewardsDue(msg.sender);
    }

    /**
     * @dev This function is a helper function that allows the caller to view all the vesting dates for the pool.
     * @return array: This function returns an array of vesting dates
     * @notice The first item in the array is start date of the vesting cliff
     */
    function printPitStopDates()
        external
        view
        override
        returns (uint256[] memory)
    {
        return pitStopDates;
    }

    /**
     * @notice View pool state
     */
    function readPoolState()
        public
        view
        override
        returns (PoolState memory poolState)
    {
        poolState = PoolState(
            poolId,
            url,
            poolDesc,
            address(this),
            address(pool),
            totalAmountStaked,
            numberOfStakers,
            maximumNumberOfStakers,
            waitingRoomOpenDate,
            raceStartDate,
            raceEndDate,
            CLAIM_TIME_AFTER_ENDTIME,
            interestRateInBps,
            MINIMUM_STAKING_PER_USER,
            MAXIMUM_STAKING_PER_USER,
            maximumInterestRateInBasisPoints,
            isInitialized,
            isDisabled
        );
        
    }

    function isValidPoolState() external override view returns(bool){
        PoolState memory poolState = readPoolState();
        return _validPoolStateValues(poolState);
    }

    function getRaceStartDate() external override view returns(uint256) {
        return raceStartDate;
    }

    function getWaitingRoomOpenDate() external override view returns(uint256) {
        return waitingRoomOpenDate;
    }

    function getDisabledStatus() external override view returns(bool) {
        return isDisabled;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev The increment part of the counter feature for stakers
     * @notice This is a counter to increment the count for the number of stakers.
     */
    function incrementCountStakers(address beneficiary) private {
        uint256 oldCount = numberOfStakers;
        uint256 newCount;
        if (s_userBalance[beneficiary] == 0) {
            numberOfStakers++;
            newCount = oldCount + 1;
        }
        emit StakersCountChanged(oldCount, newCount, msg.sender);
    }

    /**
     * @dev The decrement part of the counter feature for stakers
     * @notice This is a counter to decrement the count for the number of stakers.
     */
    function decrementCountStakers(address beneficiary) private {
        uint256 oldCount = numberOfStakers;
        uint256 newCount;
        if (s_userBalance[beneficiary] == 0) {
            numberOfStakers--;
            newCount = oldCount - 1;
        }
        emit StakersCountChanged(oldCount, newCount, msg.sender);
    }
}
