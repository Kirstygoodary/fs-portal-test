// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../core/security/AbstractSystemPause.sol";
import "../../interfaces/IAccess.sol";
import "../../interfaces/IPayToPlay.sol";

contract BoostPlays is
    IPayToPlay,
    AbstractSystemPause,
    Initializable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    /// Access contract
    IAccess private _access;
    /// token
    IERC20Upgradeable private _token;

    /// Mapping of address to total number of paid plays
    mapping(address => uint256) private _userPaidPlays;
    /// Cost per play
    uint256 private _costPerPlay;

    /* ========== EVENTS ========== */

    event UserPaidBoostPlay(address user, uint256 amount);
    event RequestUserPaidPlays();
    event CostPerPlay(uint256 costPerPlay);

    /* ========== REVERT STATEMENTS ========== */

    error FallBackBoostPlay(
        string info,
        address sender,
        uint256 amount,
        bytes data
    );

    /* ========== MODIFIERS ========== */

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyBoostRole() {
        _access.onlyBoostRole(msg.sender);
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyExecutive() {
        require(
            _access.userHasRole(_access.executive(), msg.sender),
            "BoostPlays: access forbidden"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address accessAddress,
        address systemPauseAddress,
        address token
    ) public initializer {
        _costPerPlay = 1;
        __Pausable_init();
        _access = IAccess(accessAddress);
        system = ISystemPause(systemPauseAddress);
        _token = IERC20Upgradeable(token);
    }

    /* ========== EXTERNAL ========== */

    receive() external payable {
        revert FallBackBoostPlay(
            "Boostplay receive",
            msg.sender,
            msg.value,
            ""
        );
    }

    fallback() external payable {
        revert FallBackBoostPlay(
            "Boostplay fallback",
            msg.sender,
            msg.value,
            msg.data
        );
    }

    /**
     * @dev : function that allows user pay for goes on boost game.
     * @param amount. Amount of plays
     */

    function userPayForGo(
        uint256 amount
    ) external override whenNotPaused whenSystemNotPaused {
        require(amount > 0, "amount must be greater than 0");

        uint256 tokenCost = amount * _costPerPlay;

        require(
            _token.balanceOf(msg.sender) >= tokenCost,
            "not enough tokens in account"
        );
        _userPaidPlays[msg.sender] += amount;

        _token.safeTransferFrom(msg.sender, address(this), tokenCost);

        emit UserPaidBoostPlay(msg.sender, amount);
    }

    /**
     * @dev : function thats enables admin to update the cost per play for boost
     * @param costPerPlay. cost for single play.
     */

    function setCostPerPlay(
        uint256 costPerPlay
    ) external override whenNotPaused whenSystemNotPaused onlyBoostRole {
        require(costPerPlay > 0, "cost per play must be greater than 0"); // TOD0: Review decimals
        _costPerPlay = costPerPlay;

        emit CostPerPlay(_costPerPlay);
    }

    /**
     * @dev : function thats enables executive to withdraw erc20 token held by contract to an address
     * @param amount. value to withdraw.
     * @param to. address to send the token.
     */

    function withdraw(
        uint256 amount,
        address to
    ) external override onlyExecutive {
        require(
            amount > 0 && amount <= _token.balanceOf(address(this)),
            "invalid amount"
        );
        require(to != address(0), "Boostplays: address(0) is forbidden");

        _token.safeTransfer(to, amount);
    }

    /**
     * @dev : get the number of plays a user has paid for.
     * @param addr. address to get balance on.
     */

    function getUserBalance(
        address addr
    ) external view override returns (uint256) {
        require(addr != address(0), "must be a valid address");

        return _userPaidPlays[addr];
    }

    /**
     * @dev : get cost per play for boost game.
     */

    function getCostPerPlay() external view override returns (uint256) {
        return _costPerPlay;
    }

    function pauseContract() external onlyBoostRole {
        _pause();
    }

    function unpauseContract() external onlyBoostRole {
        _unpause();
    }
}
