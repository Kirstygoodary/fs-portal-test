// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../core/security/AbstractSystemPause.sol";
import "../../interfaces/ITOKEN.sol";
import "../../interfaces/IAccess.sol";
import "../../interfaces/ISystemPause.sol";
import "../../interfaces/IRace.sol";
import "../../interfaces/IStaking.sol";

/**
@notice StakingFactory contract
@notice this contract is the staking factory contract for creating staking contracts.
@author MDRxTech
 */

contract StakingManager is Initializable, AbstractSystemPause, IRace {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    /// main access contract
    IAccess access;
    /// count of all pools
    uint256 public totalCount;
    /// count of all disabled pool
    uint256 public disabledCount;
    /// users are not allowed to have more than the maximum number of Active pools
    uint256 public maximumActivePools;
    /// mapping of id to pool address
    mapping(uint256 => address) public idToPoolAddress;
    /// mapping of id to bool isInitialized
    mapping(address => bool) private isInitialized;

    /// mapping of factory addresses
    mapping(address => bool) public factoryAddresses;
    /// mapping of staking address to bool
    mapping(address => bool) isStakingContract;
    /// staking pool's associated reward pool address
    mapping(address => address) public rewardPoolAddress;

    /* =========TENTATIVE VARIABLES ============ */
    address[] activePoolsArray;
    address[] expiredPoolsArray;
    address[] disabledPoolsArray;

    /* ========== REVERT STATEMENTS ========== */
    error CallUnsuccessful(address contractAddress);

    /* ========== EVENTS ========== */

    event NewPool(address stakingPoolAddress, address rewardPoolAddress);

    event DisabledPool(
        address stakingPoolAddress,
        address caller,
        uint256 timeOfDisablement,
        bool isActive,
        uint256 numOfDisabledPools
    );
    event FundedRewardPool(address caller, address token, uint256 amount);
    event SetMaximumPool(
        address caller,
        uint256 prevMaximumPool,
        uint256 currentMaximumPool
    );
    event SetInitialized(
        uint256 id,
        address caller,
        address raceClub,
        bool oldState,
        bool newState
    );

    /* ========== MODIFIERS ========== */

    modifier onlyStakingManagerRole() {
        access.onlyStakingManagerRole(msg.sender);
        _;
    }

    modifier onlyStakingManagerOrFactory() {
        require(
            access.userHasRole(access.stakingManagerRole(), msg.sender) ||
                access.userHasRole(access.admin(), msg.sender) ||
                factoryAddresses[msg.sender],
            "Manager: Not allowed for non-admin, non-staking, non-factory"
        );
        _;
    }

    modifier onlySystemPause() {
        access.userHasRole(access.pauseRole(), msg.sender);
        _;
    }

    modifier onlyExecutiveOrStakingManager() {
        require(
            access.userHasRole(access.executive(), msg.sender) ||
                access.userHasRole(access.admin(), msg.sender) ||
                access.userHasRole(access.stakingManagerRole(), msg.sender),
            "StakingManager: access forbidden"
        );
        _;
    }

    modifier onlyFactoryRole() {
        require(
            factoryAddresses[msg.sender],
            "Manager: Not allowed for non-factory"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _accessAddress,
        address _systemPauseAddress
    ) public initializer {
        maximumActivePools = 6;
        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
    }

    /* ========== EXTERNAL ========== */

    /**
     * @dev Update the parameters of a pool identified by the given index.
     * @param raceVariables The updated race variables to use for the pool.
     * @param index The index of the pool to update.
     * Requirements:
     * - The pool identified by the index must exist.
     * - The inputs in the race variables must be valid.
     * - The system must not be paused.
     * - The race start time for the pool must not have already passed.
     *  * It can only be called by StakingManager or Factory when the system is not paused.
     * It validates whether the pool exists, race has begun, and current time exceeds waitingRoomOpenTime.
     * If valid, it initializes the pool and activates it.
     * To update the pool once in the waitingRoomOpenTime has began and the raceStartTime is yet to begin, the previous waiting room open time MUST BE the same as the new waiting room open time.
     * Emits a {PoolInitialized} event if the pool was successfully initialized.
     * Reverts if the initialization of the pool failed.
     */
    function updatePool(
        PoolInitiator memory raceVariables,
        uint256 index
    ) external onlyStakingManagerOrFactory whenSystemNotPaused {
        require(
            idToPoolAddress[index] != address(0),
            "Manager: Pool does not exist"
        );

        address val = idToPoolAddress[index];
        bool poolInitialized = isInitialized[val];
        uint256 raceStartTime = IStaking(val).getRaceStartDate();
        uint256 waitingRoomOpenTime = IStaking(val).getWaitingRoomOpenDate();

        if (raceStartTime != 0 && block.timestamp > raceStartTime) {
            require(
                block.timestamp < raceStartTime,
                "Manager: Cannot change, Race has begun"
            );
        } else if (
            waitingRoomOpenTime != 0 &&
            block.timestamp >= waitingRoomOpenTime &&
            block.timestamp < raceStartTime
        ) {
            PoolState memory poolObject = IStaking(val).readPoolState();
            _validateInputsPastWaitingRoomOpenTime(raceVariables, poolObject);
            _initializePool(raceVariables, val, poolInitialized);
        } else {
            _validateInputs(raceVariables);
            _initializePool(raceVariables, val, poolInitialized);
        }
    }

    /**
     * @dev Initializes the pool parameters for a pool identified by the given index with the provided race variables.
     * @param raceVariables The race variables to use for the pool.
     * @param index The index of the pool to express.
     * Requirements:
     * - The pool identified by the index must exist.
     * - The caller must have the factory role.
     * - The system must not be paused.
     * Emits a {PoolInitialized} event if the pool was successfully initialized.
     * Reverts if the initialization of the pool failed.
     */
    function expressPool(
        PoolInitiator memory raceVariables,
        uint256 index,
        bool poolInitialized
    ) external onlyFactoryRole whenSystemNotPaused {
        require(
            idToPoolAddress[index] != address(0),
            "Manager: Pool does not exist"
        );
        address val = idToPoolAddress[index];
        IStaking(val).initializePoolValues(
            raceVariables._url,
            raceVariables.interestRateInBasisPoints,
            raceVariables.waitingRoomOpenDate,
            raceVariables.raceStartDate,
            raceVariables.raceEndDate,
            raceVariables.minimumStakePeruser,
            raceVariables.maximumStakePerUser,
            raceVariables.claimTimeAfterEndtime,
            raceVariables.pitStopDates,
            raceVariables.maximumNumberOfStakers,
            poolInitialized
        );

        if (poolInitialized) {
            isInitialized[val] = true;
            activePoolsArray.push(val); //push to active array.
        }
    }

    /**
     * @notice Modifies the initialization status of the pool at a given index
     * @param index The index of the pool to be updated
     * Unidirectional, will only change uninitializedPools to initialized
     */
    function setInitialized(
        uint256 index
    ) external onlyExecutiveOrStakingManager {
        require(
            idToPoolAddress[index] != address(0),
            "Manager: Pool does not exist"
        );

        address val = idToPoolAddress[index];
        bool currentState = isInitialized[val];
        require(!currentState, "Manager: Current state must be false!");
        assert(IStaking(val).isValidPoolState());

        activePoolsArray.push(val);

        isInitialized[val] = true;
        emit SetInitialized(
            index,
            msg.sender,
            val,
            currentState,
            isInitialized[val]
        );
    }

    /**
     * @notice disablePool
     * @dev Disables a staking pool. The function is only accessible by the staking manager.
     *
     * @param _index uint256: index of the pool to be disabled
     *
     * Throws When the staking system is paused
     * Throws When the caller is not the staking manager
     * Throws When the pool already has stakers
     * Throws When the staking pool is already disabled
     */

    function disablePool(uint256 _index) external onlyStakingManagerRole {
        address val = idToPoolAddress[_index];

        require(
            IStaking(val).totalStaked() == 0,
            "Manager: Cannot disable, Pool already has stakers"
        );
        require(
            !IStaking(val).getDisabledStatus(),
            "Manager: Staking pool is disabled!"
        );
        require(activePoolsArray.length > 0, "Manager: Has no active pool!");

        uint length = activePoolsArray.length; //Check for uint 8; Identify the Active Pools max on Staging

        // create a replica in memory
        address[] memory replica = new address[](length);
        replica = activePoolsArray;
        for (uint i = 0; i < length; i++) {
            if (replica[i] == val) {
                //push to disabled
                disabledPoolsArray.push(replica[i]);
                //overwrite in array
                replica[i] = replica[length - 1];
                activePoolsArray = replica;
                activePoolsArray.pop();

                disabledCount++;

                IStaking(val).disablePool();

                emit DisabledPool(
                    address(IStaking(val)),
                    msg.sender,
                    block.timestamp,
                    IStaking(val).getDisabledStatus(),
                    disabledCount
                );
                break;
            }
        }
    }

    /**
     * @notice setMaximumActivePools
     * @dev Sets the maximum number of active staking pools. This function can only be executed by the executive.
     *
     * @param amount uint256: maximum number of active staking pools
     *
     * Throws When the caller is not the executive
     * Throws When the amount is less than 6
     *
     * EVENT: SetMaximumPool - Emits an event with the previous maximum number of active staking pools,
     * the new maximum number of active staking pools, and the address of the caller
     */

    function setMaximumActivePools(
        uint256 amount
    ) external onlyExecutiveOrStakingManager {
        require(amount >= 1, "Manager: amount must be >= 1"); //TO DO: Review the effects
        uint256 prev = maximumActivePools;
        maximumActivePools = amount;
        emit SetMaximumPool(msg.sender, prev, amount);
    }

    /**
     * @notice viewPoolCount
     * @dev Returns the total number of staking pools in the system.
     *
     * @return uint256 - the total number of staking pools in the system
     */

    function viewPoolCount() external view returns (uint256) {
        return totalCount;
    }

    /**
     * @notice viewDisabledPoolCount
     * @dev Returns the total number of disabled staking pools in the system.
     *
     * @return uint256 - the total number of disabled staking pools in the system
     */

    function viewDisabledPoolCount() external view returns (uint256) {
        return disabledCount;
    }

    /**
     * @notice viewAllPools
     * @dev Returns an array of all the staking pools in the system and their state.
     *
     * @return pools PoolState[] memory - an array of all the staking pools in the system and their state
     *
     * Throws When there are no active staking pools
     */

    function viewAllPools() external view returns (PoolState[] memory pools) {
        require(totalCount > 0, "StakingManager: No Active Pools");
        pools = new PoolState[](totalCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= pools.length; i++) {
            pools[counter] = IStaking(idToPoolAddress[i]).readPoolState();
            counter++;
        }
        return pools;
    }

    /**
     * @notice viewAllPoolAddresses
     * @dev Returns an array of all the staking pool addresses in the system.
     *
     * @return pools address[] memory - an array of all the staking pool addresses in the system
     *
     * Throws When there are no active staking pools
     */

    function viewAllPoolAddresses()
        external
        view
        returns (address[] memory pools)
    {
        require(totalCount > 0, "StakingManager: No Active Pools");
        pools = new address[](totalCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= pools.length; i++) {
            pools[counter] = idToPoolAddress[i];
            counter++;
        }
        return pools;
    }

    /**
     * @notice viewActivePools
     * @dev Returns an array of all the active staking pool addresses in the system.
     *
     * @return pools address[] memory - an array of all the active staking pool addresses in the system
     *
     * Throws When there are no active staking pools
     */

    function viewActivePools() external view returns (address[] memory pools) {
        require(totalCount > 0, "StakingManager: No Active Pools");

        return activePoolsArray;
    }

    /**
     * @notice viewExpiredPoolsArray
     * @dev Returns an array of all the expired staking pool addresses in the system.
     *
     * @return pools address[] memory - an array of all the expired staking pool addresses in the system
     */

    function viewExpiredPoolsArray()
        public
        view
        returns (address[] memory pools)
    {
        return expiredPoolsArray;
    }

    /**
     * @notice viewDisabledPoolsArray
     * @dev Returns an array of all the disabled staking pool addresses in the system.
     *
     * @return  pools address[] memory - an array of all the disabled staking pool addresses in the system
     */

    function viewDisabledPoolsArray()
        external
        view
        returns (address[] memory pools)
    {
        return disabledPoolsArray;
    }

    /**
     * @notice viewRewardPoolTokenBalance
     * @dev Returns the balance of the staking pool in the specified token.
     *
     * @param _tokenAddress address: address of the token
     * @param _pool address: address of the staking pool
     *
     * @return uint256 - the balance of the staking pool in the specified token
     */

    function viewRewardPoolTokenBalance(
        address _tokenAddress,
        address _pool
    ) external view returns (uint256) {
        ITOKEN token = ITOKEN(_tokenAddress);
        return token.balanceOf(_pool);
    }

    /**
     * @notice viewPool
     * @dev Returns the state of the specified staking pool.
     *
     * @param _index uint256: index of the staking pool
     *
     * @return PoolState memory - the state of the specified staking pool
     */

    function viewPool(uint256 _index) external view returns (PoolState memory) {
        return IStaking(idToPoolAddress[_index]).readPoolState();
    }

    /**
     * @notice viewPoolByAddress
     * @dev Returns the state of the staking pool with the specified address.
     *
     * @param _pool address: address of the staking pool
     *
     * @return PoolState memory - the state of the staking pool with the specified address
     */

    function viewPoolByAddress(
        address _pool
    ) external view returns (PoolState memory) {
        return IStaking(_pool).readPoolState();
    }

    /**
     * @notice viewUserBalanceAcrossAllPools
     * @dev Returns the total balance of the specified user in all staking pools.
     *
     * @param _user address: address of the user
     *
     * @return uint256 - the total balance of the specified user in all staking pools
     *
     * Throws When there are no active staking pools
     */

    function viewUserBalanceAcrossAllPools(
        address _user
    ) external view returns (uint256) {
        require(totalCount > 0, "StakingManager: No Active Pools");
        uint256 accumulatedBalance;
        uint256 length = totalCount;

        for (uint256 i = 1; i <= length; i++) {
            uint256 userBalance = IStaking(idToPoolAddress[i]).viewUserBalance(
                _user
            );
            accumulatedBalance += userBalance;
        }
        //

        return accumulatedBalance;
    }

    /**
     * @notice getUserBalanceAtBlockNumber
     * @dev Returns the total balance of the specified user in all staking pools at a specified block number.
     *
     * @param account address: address of the user
     * @param blockNumber uint256: block number to retrieve the balance at
     *
     * @return uint256 - the total balance of the specified user in all staking pools at the specified block number
     *
     * Throws When there are no active staking pools
     */

    function getUserBalanceAtBlockNumber(
        address account,
        uint256 blockNumber
    ) external view returns (uint256) {
        uint256 accumulatedBalance;
        if (totalCount > 0) {
            PoolState[] memory pools = new PoolState[](totalCount);
            pools = this.viewAllPools();
            for (uint256 i; i < pools.length; i++) {
                accumulatedBalance += IStaking(pools[i].poolAddress)
                    .getPastCheckpoint(account, blockNumber);
            }
        }
        return accumulatedBalance;
    }

    // * ========== PUBLIC =========== *

    /**
     * @notice addNewPool
     * @dev Adds a new staking pool to the system.
     *
     * @param _id uint256: id of the staking pool
     * @param _contractAddress address: address of the staking pool contract
     *
     * @notice To increase the number of pools, the admin must either disable a pool with no deposits, or change the maximumActivePools function
     *
     * Throws When the sender is not the factory address
     * Throws When _id is not greater than 0
     * Throws When _id is not equal to the total count + 1
     * Throws When _contractAddress is equal to address(0)
     * Throws When there are already the maximum number of active staking pools
     */

    function addNewPool(
        uint256 _id,
        address _contractAddress,
        address _rewardPoolAddress
    ) public onlyFactoryRole {
        // require(factoryAddresses[msg.sender], "Manager: Access Forbidden");
        require(_id > 0, "Manager: _id must be greater than 0");
        require(_id == totalCount + 1, "Manager: invalid id");
        require(
            _contractAddress != address(0),
            "Manager: _contractAddress cannot be address(0)"
        );
        shiftExpiredPoolsFromActivePools();

        require(
            activePoolsArray.length < maximumActivePools,
            "Disable an existing pool, in order to add new pools"
        );
        idToPoolAddress[_id] = _contractAddress;

        totalCount = _id;
        isStakingContract[_contractAddress] = true;
        rewardPoolAddress[_contractAddress] = _rewardPoolAddress;

        emit NewPool(_contractAddress, _rewardPoolAddress);
    }

    /**
     * @dev This function is callable by Admin.
     * @param _factory: a new factory address
     */

    function addFactoryAddress(address _factory) public onlyStakingManagerRole {
        factoryAddresses[_factory] = true;
    }

    /**
     * @dev This function is callable by Admin.
     * @param _factory: the factory address to remove
     */

    function removeFactoryAddress(
        address _factory
    ) public onlyStakingManagerRole {
        factoryAddresses[_factory] = false;
    }

    /**
     * @notice poolChecker
     * @dev Returns true if the specified address is a staking pool contract, false otherwise.
     *
     * @param _pool address: address to check
     *
     * @return bool - true if the specified address is a staking pool contract, false otherwise
     */

    function poolChecker(address _pool) public view returns (bool) {
        return isStakingContract[_pool];
    }

    /**
     * @dev Pauses the system by setting the systemPaused flag to true and pausing all active and expired pools.
     * Accessible only to the SystemPause contract.
     * Emits a {SystemPaused} event.
     * Reverts if any of the calls to pause the pools are unsuccessful.
     */
    function pauseSystem() public virtual override onlySystemPauseContract {
        systemPaused = true;

        for (uint256 i; i < activePoolsArray.length; i++) {
            (bool success, ) = activePoolsArray[i].call(
                abi.encodeWithSignature("systemPause()")
            );
            if (!success) revert CallUnsuccessful(activePoolsArray[i]);
        }

        for (uint256 i; i < expiredPoolsArray.length; i++) {
            (bool success, ) = expiredPoolsArray[i].call(
                abi.encodeWithSignature("systemPause()")
            );
            if (!success) revert CallUnsuccessful(expiredPoolsArray[i]);
        }
    }

    /**
     * @dev Unpauses the system by setting the systemPaused flag to false and unpausing all active and expired pools.
     * Accessible only to the SystemPause contract.
     * Emits a {SystemUnpaused} event.
     * Reverts if any of the calls to unpause the pools are unsuccessful.
     */
    function unpauseSystem() public virtual override onlySystemPauseContract {
        systemPaused = false;

        for (uint256 i; i < activePoolsArray.length; i++) {
            (bool success, ) = activePoolsArray[i].call(
                abi.encodeWithSignature("systemUnpause()")
            );
            if (!success) revert CallUnsuccessful(activePoolsArray[i]);
        }

        for (uint256 i; i < expiredPoolsArray.length; i++) {
            (bool success, ) = expiredPoolsArray[i].call(
                abi.encodeWithSignature("systemUnpause()")
            );
            if (!success) revert CallUnsuccessful(expiredPoolsArray[i]);
        }
    }

    // * ========== INTERNAL =========== *
    /**
     * @notice shiftExpiredPoolsFromActivePools
     * @dev Transfers expired staking pools from the active pool array to the expired pool array.
     *
     * When a staking pool's end time has been reached, this function will identify the pool
     * and transfer it from the active pool array to the expired pool array.
     */

    function shiftExpiredPoolsFromActivePools() internal {
        // First create an array in memory with the maximum possible length

        uint counter = 0;
        uint[] memory indexArr = new uint[](activePoolsArray.length);

        for (uint i = 0; i < activePoolsArray.length; i++) {
            if (activePoolsArray.length == 0) {
                break;
            } else if (!IStaking(activePoolsArray[i]).hasPoolExpired()) {
                indexArr[counter] = i;
                counter++;
            } else if (IStaking(activePoolsArray[i]).hasPoolExpired()) {
                expiredPoolsArray.push(activePoolsArray[i]);
            }
        }

        // Create a new array with the actual length (i.e., counter)
        address[] memory newArray = new address[](counter);

        // Copy the relevant elements to the new array
        for (uint i = 0; i < counter; i++) {
            if (activePoolsArray.length == 0) {
                break;
            } else {
                newArray[i] = activePoolsArray[indexArr[i]];
            }
        }

        // Update the activePoolsArray with the newArray
        activePoolsArray = newArray;
    }

    /**
     * @dev This removes any expired pools from the active array.
     */
    function shiftArray() external onlySystemPause {
        shiftExpiredPoolsFromActivePools();
    }

    /**
     * @dev This function initializes and activates the pool.
     * If the pool has not been initialized, it pushes the pool to the active pools array.
     * @param raceVariables The variables required to initialize the pool.
     * @param val The address of the pool to be initialized and activated.
     */
    function _initializePool(
        PoolInitiator memory raceVariables,
        address val,
        bool poolInitialized
    ) internal {
        IStaking(val).initializePoolValues(
            raceVariables._url,
            raceVariables.interestRateInBasisPoints,
            raceVariables.waitingRoomOpenDate,
            raceVariables.raceStartDate,
            raceVariables.raceEndDate,
            raceVariables.minimumStakePeruser,
            raceVariables.maximumStakePerUser,
            raceVariables.claimTimeAfterEndtime,
            raceVariables.pitStopDates,
            raceVariables.maximumNumberOfStakers,
            poolInitialized
        );
    }
}
