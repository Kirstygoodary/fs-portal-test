// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {IERC20} from "../../lib/IERC20.sol";

interface IFxERC20 {
    function fxManager() external returns (address);

    function connectedToken() external returns (address);

    function initialize(
        address _fxManager,
        address _connectedToken,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */

    /* ========== FUNCTIONS ========== */

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function getTotalAccounts() external view returns (uint256);

    function getPastVotes(
        address account,
        uint256 blockNumber
    ) external view returns (uint256);

    function getProposalVotes(
        address account,
        uint256 blockNumber
    ) external view returns (uint256);

    function getVotes(address account) external view returns (uint256);

    function getCheckpointBlockNumber(
        address account,
        uint32 pos
    ) external view returns (uint32);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function delegates(address account) external view returns (address);

    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pauseContract() external;

    function unpauseContract() external;
}
