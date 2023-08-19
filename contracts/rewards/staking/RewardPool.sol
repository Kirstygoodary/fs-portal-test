// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IAccess.sol";
import "../../interfaces/IRewardPool.sol";
import "./Staking.sol";
import "./StakingManager.sol";

/**
@title RewardPool contract
@notice this contract is the reward pool contract for staking.
@author MDRxTech
 */

contract RewardPool is IRewardPool, ReentrancyGuard, Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// The access contract
    IAccess access;
    /// The reward token
    IERC20Upgradeable token;
    /// The staking factory
    StakingManager manager;
    Staking race;

    /* ========== EVENTS ========== */

    event FundedAccount(
        address caller,
        address beneficiary,
        uint256 amount,
        uint256 contractTokenBalance
    );
    event Withdrawal(
        address caller,
        address beneficiary,
        uint256 amount,
        uint256 contractTokenBalance
    );

    /* ========== REVERT STATEMENTS ========== */

    error Fallback(string func, address sender, uint256 amount, bytes data);
    error Receive(string func, address sender, uint256 amount);

    /* ========== MODIFIERS ========== */

    modifier onlyExecutive() {
        require(
            access.userHasRole(access.executive(), msg.sender),
            "RewardPool: access forbidden"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _token,
        address _accessAddress,
        address _manager
    ) ReentrancyGuard() {
        token = IERC20Upgradeable(_token);
        access = IAccess(_accessAddress);
        manager = StakingManager(_manager);
    }

    /* ========== EXTERNAL ========== */

    receive() external payable {
        revert Receive("receive", msg.sender, msg.value);
    }

    fallback() external payable {
        revert Fallback("fallback", msg.sender, msg.value, msg.data);
    }

    /**
     * @dev This function allows the Executive to withdraw any left over tokens not used
     * @param amount This specifies the amount to be withdrawn
     * @param recepient This specifies the destination address to receive the tokens
     */

    function withdraw(
        uint256 amount,
        address recepient
    ) external virtual override onlyExecutive {
        require(
            recepient != address(0),
            "Reward pool: receiver address is zero address"
        );

        require(amount > 0, "Reward pool: Amount must be greater than zero");
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "Pool: Amount greater than balance");
        require(
            amount <=
                (contractBalance - Staking(owner()).getTotalPayableRewards()),
            "Pool: Amount exceeds payable rewards!"
        );

        token.safeTransfer(recepient, amount);

        emit Withdrawal(
            msg.sender,
            recepient,
            amount,
            token.balanceOf(address(this))
        );
    }

    /**
     * @notice This function allows the staking contract to fund a user's reward claim.
     * @dev This function can only be called by the staking contract
     * @param to: This is the address being funded
     * @param amount: This is the amount to be paid out
     *
     */
    function fundStaker(
        address to,
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        require(
            contractBalance >= amount,
            "Pool: Insufficient funds in the pool"
        );

        token.safeTransfer(to, amount); //Please refer to the first test case in claimRewards.test.ts, it demonstrates that the rewardpool is debited for this function call.
        emit FundedAccount(
            msg.sender,
            to,
            amount,
            token.balanceOf(address(this))
        );
    }

    /* ========== PUBLIC ========== */

    /**
     * @notice This function calls the balance left in the pool.
     * @return uint This function returns the balance of the ERC20 tokens in the contract in uint.
     */
    function poolBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
