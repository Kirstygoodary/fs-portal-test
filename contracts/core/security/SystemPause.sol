// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/IAccess.sol";
import "../../interfaces/ISystemPause.sol";

import "./AbstractSystemPause.sol";
import "../Multicall.sol";

/**
@title  System Pause contract 
 */
contract SystemPause is ISystemPause, Multicall {
    /* ========== STATE DECLARATIONS ========== */

    /* ========== STATE VARIABLES ========== */

    /// Main access contract
    IAccess access;

    /// mapping of active smart contract modules
    struct moduleData {
        address add;
        string name;
    }
    uint public moduleId = 0;
    /// mapping module id => module implementation address
    mapping(uint => moduleData) moduleDataById;
    /// mapping module implementation address => module id
    mapping(address => uint) moduleIdByAddress;
    /// mapping module name => module id
    mapping(string => uint) moduleIdByName;

    /// StakingManager address
    address stakingManager;

    /* ========== MODIFIERS ========== */

    modifier onlyEmergencyRole() {
        access.onlyEmergencyRole(msg.sender);
        _;
    }

    modifier onlyDeployerOrStakingManager() {
        if (stakingManager == address(0)) revert UpdateStakingManagerAddress();
        require(
            access.userHasRole(access.deployer(), msg.sender) ||
                msg.sender == stakingManager,
            "Unauthorised Access"
        );
        _;
    }

    modifier onlyDeployer() {
        if (!access.userHasRole(access.deployer(), msg.sender))
            revert UnauthorisedAccess();
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _accessAddress) {
        access = IAccess(_accessAddress);
    }

    /* ========== EXTERNAL ========== */

    /**
     * @dev Sets the address of the staking manager smart contract
     * @param _stakingManagerAddress the contract address to set
     */
    function setStakingManager(
        address _stakingManagerAddress
    ) external virtual override onlyDeployer {
        if (_stakingManagerAddress == address(0)) revert InvalidAddress();
        stakingManager = _stakingManagerAddress;
    }

    // pauses active or expired pools
    // isActive = true will pause active pools
    // isActive = false, will pause expired pools
    function pausePools(bool isActive) external onlyEmergencyRole {
        if (isActive) {
            StakingManagerPeriphery(stakingManager).shiftArray();
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewActivePools();

            for (uint256 i; i < pools.length; i++) {
                if (!StakingPeriphery(pools[i]).pauseStatus()) {
                    (bool success, ) = pools[i].call(
                        abi.encodeWithSignature("systemPause()")
                    );
                    if (!success) revert CallUnsuccessful(pools[i]);
                }
            }
        } else {
            StakingManagerPeriphery(stakingManager).shiftArray();
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewExpiredPoolsArray();
            for (uint256 i; i < pools.length; i++) {
                if (!StakingPeriphery(pools[i]).pauseStatus()) {
                    (bool success, ) = pools[i].call(
                        abi.encodeWithSignature("systemPause()")
                    );
                    if (!success) revert CallUnsuccessful(pools[i]);
                }
            }
        }
    }

    // unpauses active or expired pools
    // isActive = true will unpause active pools
    // isActive = false, will unpause expired pools
    function unPausePools(bool isActive) external onlyEmergencyRole {
        if (isActive) {
            StakingManagerPeriphery(stakingManager).shiftArray();
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewActivePools();
            for (uint256 i; i < pools.length; i++) {
                if (StakingPeriphery(pools[i]).pauseStatus()) {
                    (bool success, ) = pools[i].call(
                        abi.encodeWithSignature("systemUnpause()")
                    );
                    if (!success) revert CallUnsuccessful(pools[i]);
                }
            }
        } else {
            StakingManagerPeriphery(stakingManager).shiftArray();
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewExpiredPoolsArray();
            for (uint256 i; i < pools.length; i++) {
                if (StakingPeriphery(pools[i]).pauseStatus()) {
                    (bool success, ) = pools[i].call(
                        abi.encodeWithSignature("systemUnpause()")
                    );
                    if (!success) revert CallUnsuccessful(pools[i]);
                }
            }
        }
    }

    // pauses an individual pool
    function pausePool(address _pool) external onlyEmergencyRole {
        require(
            StakingManagerPeriphery(stakingManager).poolChecker(_pool),
            "The address is not an intialised pool"
        );
        (bool success, ) = _pool.call(abi.encodeWithSignature("systemPause()"));
        if (!success) revert CallUnsuccessful(_pool);
    }

    // unpauses an individual pool
    function unPausePool(address _pool) external onlyEmergencyRole {
        require(
            StakingManagerPeriphery(stakingManager).poolChecker(_pool),
            "The address is not an intialised pool"
        );
        (bool success, ) = _pool.call(
            abi.encodeWithSignature("systemUnpause()")
        );
        if (!success) revert CallUnsuccessful(_pool);
    }

    /**
     * @dev Pauses modules, such as governance, staking manager/factory
     * and others.
     * Calls the pauseSystem function in the module smart contract
     * When Staking manager module is paused, it will do the cascading
     * for pause and unpause
     * i.e., pause active and expired staking pools
     * managed by staking manager itself
     * @param id the module id to pause
     */
    function pauseModule(uint id) external override onlyEmergencyRole {
        bool paused = true;

        (bool success, ) = moduleDataById[id].add.call(
            abi.encodeWithSignature("pauseSystem()")
        );
        if (!success) revert CallUnsuccessful(moduleDataById[id].add);

        emit PauseStatus(id, paused);
    }

    /**
     * @dev Reverts the action of the pause function.
     * Unpauses a module. Calls the unpauseSystem function in the module
     * smart contract
     * @param id the module id to unpause
     */
    function unPauseModule(uint id) external override onlyEmergencyRole {
        bool paused = false;

        (bool success, ) = moduleDataById[id].add.call(
            abi.encodeWithSignature("unpauseSystem()")
        );
        if (!success) revert CallUnsuccessful(moduleDataById[id].add);

        emit PauseStatus(id, paused);
    }

    /**
     * @dev Creates a new module and maps the contract address to the
     * assigned module name and id for uniqueness.
     * @param name the name of the module, e.g., MODULEID__STAKINGMANAGER
     * @param _contractAddress the address of the module's smart contract
     */
    function createModule(
        string memory name,
        address _contractAddress
    ) external override onlyDeployerOrStakingManager {
        moduleId++;
        if (_contractAddress == address(0)) revert InvalidAddress();
        if (bytes(name).length == 0) revert InvalidModuleName();
        require(
            bytes(moduleDataById[moduleId].name).length == 0,
            "Module already exists with id"
        );
        require(moduleIdByName[name] == 0, "Module already exists with name");

        moduleDataById[moduleId].add = _contractAddress;
        moduleDataById[moduleId].name = name;
        moduleIdByAddress[_contractAddress] = moduleId;
        moduleIdByName[name] = moduleId;

        emit NewModule(moduleId, _contractAddress, name);
    }

    /**
     * @dev Updates the contract address mapped to an already created module id.
     * This will revert if the module has not been created.
     * Or if the existing module is not paused
     * @param id the module id
     * @param _contractAddress the new smart contract address for the module
     */
    function updateModule(
        uint id,
        address _contractAddress
    ) external override onlyDeployerOrStakingManager {
        if (_contractAddress == address(0)) revert InvalidAddress();
        // revert if current implementation is not zero address
        // and is not paused
        require(!getModuleStatusWithId(id), "Existing module not paused");

        moduleDataById[id].add = _contractAddress;
        moduleIdByAddress[_contractAddress] = id;

        emit UpdatedModule(id, _contractAddress, moduleDataById[id].name);
    }

    /**
     * @dev Returns the status of a module, i.e., whether it is active or not active.
     * If the module has been paused, this will return false (inactive) else
     * it will return true.
     * @param id the module id
     * @return isActive
     */
    function getModuleStatusWithId(
        uint id
    ) public view override returns (bool isActive) {
        isActive = !AbstractSystemPause(moduleDataById[id].add).systemPaused();
    }

    /**
     * @dev Returns the status of a module, i.e., whether it is active or not active.
     * If the module has been paused, this will return false (inactive) else
     * it will return true.
     * @param _contractAddress the module smart contract address
     * @return isActive
     */
    function getModuleStatusWithAddress(
        address _contractAddress
    ) public view override returns (bool isActive) {
        isActive = !AbstractSystemPause(_contractAddress).systemPaused();
    }

    /**
     * @dev Returns the smart contract address of a module
     * given the module id.
     * @param id the module id
     * @return module the smart contract address of the module
     */
    function getModuleAddressWithId(
        uint id
    ) external view override returns (address module) {
        module = moduleDataById[id].add;
    }

    /**
     * @dev Returns the module name assigned to a given module id.
     * @param id the module id
     * @return name the name assigned to the module
     */
    function getModuleNameWithId(
        uint id
    ) external view override returns (string memory name) {
        name = moduleDataById[id].name;
    }

    /**
     * @dev Returns the module id assigned to a given module address.
     * @param _contractAddress the module address
     * @return id the module id assigned to the given address
     */
    function getModuleIdWithAddress(
        address _contractAddress
    ) external view override returns (uint id) {
        id = moduleIdByAddress[_contractAddress];
    }

    /**
     * @dev Returns the module id assigned to a given module name.
     * @param name the module name
     * @return id the module id assigned to the name
     */
    function getModuleIdWithName(
        string memory name
    ) external view override returns (uint id) {
        id = moduleIdByName[name];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

interface StakingManagerPeriphery {
    function poolChecker(address _pool) external view returns (bool);

    function viewActivePools() external view returns (address[] memory pools);

    function viewExpiredPoolsArray()
        external
        view
        returns (address[] memory pools);

    function shiftArray() external;
}

interface StakingPeriphery {
    function pauseStatus() external view returns (bool);
}
