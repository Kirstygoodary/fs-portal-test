// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {ERC20} from "../../lib/ERC20.sol";
import {IFxERC20} from "./IFxERC20.sol";

import "./ERC20VotesUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

/**
 * @title FxERC20 represents fx erc20 on Polygon
 */
contract FxERC20Child is
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    IFxERC20
{
    address internal _fxManager;
    address internal _connectedToken;
    /// total accounts
    uint256 totalAccounts;

    string private __name;
    string private __symbol;
    uint8 private __decimals;

    event TotalAccounts(uint256 totalAccounts);

    function initialize(
        address fxManager_,
        address connectedToken_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public override {
        __ERC20Votes_init();
        __ERC20Permit_init("RacingToken2");
        require(
            _fxManager == address(0x0) && _connectedToken == address(0x0),
            "Token is already initialized"
        );
        _fxManager = fxManager_;
        _connectedToken = connectedToken_;

        // setup meta data
        setupMetaData(name_, symbol_, decimals_);
    }

    /**
    @dev this function returns the total accounts
    @return uint256 total accounts that own TOKEN
     */

    function getTotalAccounts() external view returns (uint256) {
        return totalAccounts;
    }

    // fxManager returns fx manager
    function fxManager() public view override returns (address) {
        return _fxManager;
    }

    // connectedToken returns root token
    function connectedToken() public view override returns (address) {
        return _connectedToken;
    }

    // setup name, symbol and decimals
    function setupMetaData(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        require(msg.sender == _fxManager, "Invalid sender");
        _setupMetaData(_name, _symbol, _decimals);
    }

    /**
    @dev this function returns past votes for a user at a specified block number
    @param account. The account to get past votes for
    @param blockNumber. The block number checkpoint to get past votes
    @return the past votes for a user at a specified block number
     */
    function getPastVotes(
        address account,
        uint256 blockNumber
    ) public view virtual override returns (uint256) {
        return super.getPastVotes(account, blockNumber);
    }

    /**
     * @dev Returns the address currently delegated for the specified account.
     * Overrides the `delegates` function in `ITOKEN` and `ERC20VotesUpgradeable`.
     * @param account The address of the account to check.
     * @return The address currently delegated for the specified account.
     */
    function delegates(
        address account
    ) public view virtual override returns (address) {
        return super.delegates(account);
    }

    /**
    @dev this function returns the allowance for spender.
    @param _owner. The owner of approved tokens. 
    @param spender. The amount spender is approved for. 
    @return uint256. The amount spender is approved for
     */

    function allowance(
        address _owner,
        address spender
    ) public view virtual override returns (uint256) {
        return super.allowance(_owner, spender);
    }

    /**
    @dev this function is for transferring tokens. 
    Callable when system is not paused and contract is not paused.
    @return bool if the transfer was successful
     */

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (amount != 0) _increaseTotalAccounts(to);
        super.transfer(to, amount);
        if (amount != 0) _decreaseTotalAccounts(msg.sender);
        return true;
    }

    /**
    @dev this function is for third party transfer of tokens. 
    Callable when system is not paused and contract is not paused.
    @return true if the transfer was successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (amount != 0) _increaseTotalAccounts(to);
        super.transferFrom(from, to, amount);
        if (amount != 0) {
            _decreaseTotalAccounts(from);
        }
        return true;
    }

    /**
    @dev approve function to approve spender with amount. 
    Can be called when system and this contract is unpaused.
    @param spender. The approved address. 
    @param amount. The amount spender is approved for. 
    @return true if the approval was successful
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        return super.approve(spender, amount);
    }

    /**
    @dev this function returns the balance of account
    @param account. The account to return balance for
    @return balance 
     */

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return super.balanceOf(account);
    }

    /**
    @dev this function returns the total supply
     */

    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply();
    }

    /**
    @dev this function returns the user's votes
    @param account. The account to return votes for
    @return the user's total votes
     */

    function getVotes(
        address account
    ) public view virtual override returns (uint256) {
        return super.getVotes(account);
    }

    function getProposalVotes(
        address account,
        uint256 blockNumber
    ) external view virtual returns (uint256) {
        return _getProposalVotes(account, blockNumber);
    }

    /**
    @dev internal function which increases total accounts holding
    @param _account. It checks that account is not address zero and account's balance is zero. 
     */

    function _increaseTotalAccounts(address _account) internal {
        if (_account != address(0) && balanceOf(_account) == uint256(0))
            ++totalAccounts;

        emit TotalAccounts(totalAccounts);
    }

    /**
    @dev internal function which decreases total accounts holding
    @param _account. It checks that account is not address zero and account's balance is zero. 
     */

    function _decreaseTotalAccounts(address _account) internal {
        if (_account != address(0) && balanceOf(_account) == uint256(0))
            --totalAccounts;

        emit TotalAccounts(totalAccounts);
    }

    function getCheckpointBlockNumber(
        address account,
        uint32 pos
    ) external view virtual returns (uint32) {
        Checkpoint memory checkpoint = checkpoints(account, pos);

        return checkpoint.fromBlock;
    }

    function mint(address user, uint256 amount) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _burn(user, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20VotesUpgradeable, ERC20Upgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20VotesUpgradeable, ERC20Upgradeable) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20VotesUpgradeable, ERC20Upgradeable) {
        super._burn(account, amount);
    }

    function _setupMetaData(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal virtual {
        __name = name_;
        __symbol = symbol_;
        __decimals = decimals_;
    }
}
