// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../core/security/AbstractSystemPause.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/IStakingFactory.sol";
import "../../interfaces/ITOKEN.sol";
import "../../interfaces/IAccess.sol";
import "../../interfaces/IRace.sol";

import "./Staking.sol";
import "./RewardPool.sol";
import "./StakingManager.sol";
import "./RewardPool.sol";

/**
@title StakingFactory contract
@notice this contract is the staking factory contract for creating staking contracts.
@author MDRxTech
 */

contract StakingFactory is Initializable, AbstractSystemPause, IRace {
    event ExpressPoolSuccessful(
        uint indexed index,
        address racePool,
        address rewardPool
    );
    event DummyPoolSuccessful(
        uint indexed index,
        address racePool,
        address rewardPool
    );

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    /// main access contract
    IAccess access;
    /// count of all pools
    StakingManager manager;

    uint256 poolIndexNumber;

    uint256 maximumInterestRateInBasisPoints;

    address tokenAddress;

    /* ========== MODIFIERS ========== */

    modifier onlyStakingFactoryRole() {
        access.onlyStakingFactoryRole(msg.sender);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _accessAddress,
        address _systemPauseAddress,
        address _stakingManager,
        address _tokenAddress
    ) public initializer {
        require(
            _accessAddress != address(0),
            "Factory: _accessAddress is address(0)"
        );
        require(
            _systemPauseAddress != address(0),
            "Factory: _systemPauseAddress is address(0)"
        );
        require(
            _stakingManager != address(0),
            "Factory: _systemPauseAddress is address(0)"
        );
        require(
            _tokenAddress != address(0),
            "Factory: _tokenAddress is address(0)"
        );

        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        manager = StakingManager(_stakingManager);
        tokenAddress = _tokenAddress;
        maximumInterestRateInBasisPoints = 100 * 50;
        poolIndexNumber = 1;
    }

    /* ========== EXTERNAL ========== */

    /// @dev Create a new race
    /// @notice This function creates a new race based on the given PoolInitiator struct.
    /// @dev This function can only be called by the StakingFactoryRole and when the system is not paused.
    /// @param raceVariables A PoolInitiator struct containing the race configuration details.
    /// Emits ExpressPoolSuccessful event if the race is valid, otherwise emits DummyPoolSuccessful event.

    function createNewRace(
        PoolInitiator memory raceVariables,
        bool isInitialized
    ) external onlyStakingFactoryRole whenSystemNotPaused {
        uint index = poolIndexNumber;
        _validateInputs(raceVariables);
        (RewardPool rewardPoolInstance, Staking stakingInstance) = raceDefiner(
            raceVariables
        );
        manager.expressPool(raceVariables, index, isInitialized);
            emit ExpressPoolSuccessful(
                index,
                address(stakingInstance),
                address(rewardPoolInstance)
            );
    }

    /* ========== PRIVATE ========== */
    /**
     * @dev Creates a new instance of the RewardPool contract.
     * @return The new RewardPool contract instance.
     */
    function createRewardPoolInstance() private returns (RewardPool) {
        RewardPool rewardPoolInstance = new RewardPool(
            tokenAddress,
            address(access),
            address(manager)
        );
        return rewardPoolInstance;
    }

    /**
     * @dev Creates a new instance of the Staking contract.
     * @return The new Staking contract instance.
     */
    function createStakingInstance() private returns (Staking) {
        Staking stakingInstance = new Staking();
        return stakingInstance;
    }

    /**
     * @dev Defines a new race by creating a new instance of the RewardPool contract and a new instance of the Staking contract,
     *      transferring ownership of the RewardPool to the Staking contract, initializing the Staking contract with the given
     *      race variables, and adding the new pool to the StakingManager.
     * @param raceVariables The variables defining the new race.
     * @return A tuple of the new RewardPool and Staking contract instances.
     */
    function raceDefiner(
        PoolInitiator memory raceVariables
    ) private returns (RewardPool, Staking) {
        RewardPool rewardPoolInstance = createRewardPoolInstance();
        Staking stakingInstance = createStakingInstance();
        address contractAddr = address(stakingInstance);
        rewardPoolInstance.transferOwnership(contractAddr);

        stakingInstance.initialize(
            address(access),
            address(system),
            address(manager),
            address(this),
            tokenAddress,
            address(rewardPoolInstance),
            poolIndexNumber,
            abi.encodePacked(raceVariables._name, raceVariables._type),
            maximumInterestRateInBasisPoints
        );
        // add new pool
        manager.addNewPool(
            poolIndexNumber,
            address(stakingInstance),
            address(rewardPoolInstance)
        );
        poolIndexNumber++;
        return (rewardPoolInstance, stakingInstance);
    }
}
