// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {ERC20} from "../../lib/ERC20.sol";
import {IFxERC20} from "./IFxERC20.sol";

import "./ERC20Votes.sol";

/**
 * @title FxERC20 represents fx erc20 on Polygon
 */
contract FxERC20Child is IFxERC20, ERC20Votes {
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
        ERC20Votes();
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

    function getTotalAccounts() external view override returns (uint256) {
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
    ) external view virtual override returns (uint256) {
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
    ) external view virtual override returns (uint32) {
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
