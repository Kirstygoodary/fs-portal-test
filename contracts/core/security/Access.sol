// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/IAccess.sol";

/**
@title Access contract
@author MDRxTech
 */

contract Access is Initializable, AccessControlUpgradeable, IAccess {
    /* ========== STATE VARIABLES ========== */

    /// constant variable for EXECUTIVE
    bytes32 constant EXECUTIVE = keccak256("EXECUTIVE");
    /// constant variable for ADMIN
    bytes32 constant ADMIN = keccak256("ADMIN");
    /// constant variable for DEPLOYER
    bytes32 constant DEPLOYER = keccak256("DEPLOYER");
    /// constant variable for EMERGENCY_ROLE
    bytes32 constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    /// constant variable for TOKEN_ROLE
    bytes32 constant TOKEN_ROLE = keccak256("TOKEN_ROLE");
    /// constant variable for PAUSE_ROLE
    bytes32 constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    /// constant variable for GOVERNANCE_ROLE
    bytes32 constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    /// constant variable for BOOST_ROLE
    bytes32 constant BOOST_ROLE = keccak256("BOOST_ROLE");
    /// constant variable for STAKING_ROLE
    bytes32 constant STAKING_ROLE = keccak256("STAKING_ROLE");
    /// constant variable for REWARD_DROP_ROLE
    bytes32 constant REWARD_DROP_ROLE = keccak256("REWARD_DROP_ROLE");
    /// constant variable for STAKING_FACTORY_ROLE
    bytes32 constant STAKING_FACTORY_ROLE = keccak256("STAKING_FACTORY_ROLE");
    /// constant variable for STAKING_MANAGER_ROLE
    bytes32 constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _executive,
        address _admin,
        address _emergencyRole
    ) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _executive);
        _grantRole(EXECUTIVE, _executive);
        _grantRole(ADMIN, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEPLOYER, msg.sender);
        _grantRole(EMERGENCY_ROLE, _emergencyRole);

       
    }

    /* ========== EXTERNAL ========== */

    /**@dev this function returns bool is the caller has a role
    @param _role. bytes32 for role 
    @param _address. The caller's address
    @return bool if the caller has a role
    */
    function userHasRole(
        bytes32 _role,
        address _address
    ) public view override returns (bool) {
        return hasRole(_role, _address);
    }

    /** @dev this function checks if the caller has a governance role and reverts if false
    @param _caller. The caller's address
    */

    function onlyGovernanceRole(address _caller) external view override {
        require(
            userHasRole(governanceRole(), _caller) ||
                userHasRole(admin(), _caller),
            "Governance: access forbidden"
        );
    }

    /** @dev this function checks if the caller has a TOKEN role and reverts if false
    @param _caller. The caller's address
    */

    function onlyTokenRole(address _caller) external view override {
        require(
            userHasRole(tokenRole(), _caller) ||
                userHasRole(executive(), _caller),
            "TOKEN: access forbidden"
        );
    }

    /** @dev this function checks if the caller has an Emergency role and reverts if false
    @param _caller. The caller's address
    */

    function onlyEmergencyRole(address _caller) external view override {
        require(
            userHasRole(emergencyRole(), _caller) ||
                userHasRole(pauseRole(), _caller),
            "SystemPause: access forbidden"
        );
    }

    function onlyStakingPauserRole(address _caller) external view override {
        require(
            // admin and staking manager
            userHasRole(admin(), _caller) ||
                userHasRole(stakingManagerRole(), _caller) ||
                // emergency
                userHasRole(emergencyRole(), _caller) ||
                userHasRole(pauseRole(), _caller),
            "StakingManager: access forbidden"
        );
    }

    /** @dev this function checks if the caller has a Boost role and reverts if false
    @param _caller. The caller's address
    */

    function onlyBoostRole(address _caller) external view override {
        require(
            userHasRole(admin(), _caller) || userHasRole(boostRole(), _caller),
            "BoostPlays: access forbidden"
        );
    }

    /** @dev this function checks if the caller has a RewardDrop role and reverts if false
    @param _caller. The caller's address
    */

    function onlyRewardDropRole(address _caller) external view override {
        require(
            userHasRole(rewardDropRole(), _caller) ||
                userHasRole(admin(), _caller),
            "RewardDropERC20: access forbidden"
        );
    }

    /** @dev this function checks if the caller has a Staking role and reverts if false
    @param _caller. The caller's address
    */

    function onlyStakingRole(address _caller) external view override {
        require(
            userHasRole(admin(), _caller) ||
                userHasRole(stakingRole(), _caller),
            "Staking: access forbidden"
        );
    }

    /** @dev this function checks if the caller has a StakingFactory role and reverts if false
    @param _caller. The caller's address
    */

    function onlyStakingFactoryRole(address _caller) external view override {
        require(
            userHasRole(admin(), _caller) ||
                userHasRole(stakingFactoryRole(), _caller),
            "StakingFactory: access forbidden"
        );
    }

    /** @dev this function checks if the caller has a StakingManager role and reverts if false
    @param _caller. The caller's address
    */

    function onlyStakingManagerRole(address _caller) external view override {
        require(
            userHasRole(admin(), _caller) ||
                userHasRole(stakingManagerRole(), _caller),
            "StakingManager: access forbidden"
        );
    }

    /**@dev this function returns bytes32  EXECUTIVE
     */
    function executive() public pure override returns (bytes32) {
        return EXECUTIVE;
    }

    /**@dev this function returns bytes32 ADMIN
     */
    function admin() public pure override returns (bytes32) {
        return ADMIN;
    }

    /**@dev this function returns bytes32 DEPLOYER
     */
    function deployer() public pure override returns (bytes32) {
        return DEPLOYER;
    }

    /**@dev this function returns bytes32 EMERGENCY
     */
    function emergencyRole() public pure override returns (bytes32) {
        return EMERGENCY_ROLE;
    }

    /**@dev this function returns bytes32 TOKEN_ROLE
     */
    function tokenRole() public pure override returns (bytes32) {
        return TOKEN_ROLE;
    }

    /**@dev this function returns bytes32 PAUSE_ROLE
     */
    function pauseRole() public pure override returns (bytes32) {
        return PAUSE_ROLE;
    }

    /**@dev this function returns bytes32 GOVERNANCE_ROLE
     */
    function governanceRole() public pure override returns (bytes32) {
        return GOVERNANCE_ROLE;
    }

    /**@dev this function returns bytes32 BOOST_ROLE
     */
    function boostRole() public pure override returns (bytes32) {
        return BOOST_ROLE;
    }

    /**@dev this function returns bytes32 STAKING_ROLE
     */
    function stakingRole() public pure override returns (bytes32) {
        return STAKING_ROLE;
    }

    /**@dev this function returns bytes32 STAKING_FACTORY_ROLE
     */
    function stakingFactoryRole() public pure override returns (bytes32) {
        return STAKING_FACTORY_ROLE;
    }

    /**@dev this function returns bytes32 STAKING_MANAGER_ROLE
     */
    function stakingManagerRole() public pure override returns (bytes32) {
        return STAKING_MANAGER_ROLE;
    }

    /**@dev this function returns bytes32 REWARD_DROP_ROLE
     */
    function rewardDropRole() public pure override returns (bytes32) {
        return REWARD_DROP_ROLE;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
