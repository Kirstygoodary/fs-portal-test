// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../core/security/AbstractSystemPause.sol";

import "../../interfaces/IAccess.sol";
import "./RewardDrop.sol";

/**
@title RewardDropERC20 contract
@notice this contract is the reward drop contract for an ERC20 token.
@author MDRxTech
 */

contract RewardDropERC20 is RewardDrop, Pausable, AbstractSystemPause {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    /// Token for distributing rewards
    IERC20Upgradeable token;
    /// Main access contract
    IAccess access;
    /// id
    uint256 id;
    /// grand total of rewards to distribute
    uint256 public grandTotal;
    /// minimum delay period from creating a reward drop to claim start time.
    uint256 public claimStartDelay;
    /// minimum claim period from claim start to claim end
    uint256 public minimumClaimPeriod;
    /// cap on maximum claim per winner
    uint256 public maximumClaimPerWinner;
    /// cap on maximum winners per reward drop
    uint256 public maximumWinners;
    /// mapping of id to RewardDrop
    mapping(uint256 => RewardDrop) public rewardDrops;

    /* ========== MODIFIERS ========== */

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyRewardDropRole() {
        access.onlyRewardDropRole(msg.sender);
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyExecutive() {
        require(
            access.userHasRole(access.executive(), msg.sender),
            "RewardDropERC20: access forbidden"
        );
        _;
    }

    /**
     @dev this modifier reverts if the claim expiry is in the future.
     */

    modifier claimExpired(uint256 _id) {
        if (!_claimExpired(_id))
            revert ClaimPeriodNotExpired(
                rewardDrops[_id].claimEnd,
                block.timestamp
            );
        _;
    }

    /**
     @dev this modifier will revert if the airdrop if paused
     */

    modifier onlyActive(uint256 _id) {
        if (rewardDrops[_id].state != State.Active)
            revert InvalidRewardDropState(_id, rewardDrops[_id].state);
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _accessAddress,
        address _systemPauseAddress,
        address _tokenAddress,
        uint256 _claimStartDelay,
        uint256 _minimumClaimPeriod,
        uint256 _maximumClaimPerWinner,
        uint256 _maximumWinners
    ) {
        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        token = IERC20Upgradeable(_tokenAddress);
        claimStartDelay = _claimStartDelay;
        minimumClaimPeriod = _minimumClaimPeriod;
        maximumClaimPerWinner = _maximumClaimPerWinner;
        maximumWinners = _maximumWinners;
    }

    /* ========== EXTERNAL ========== */

    receive() external payable {
        revert Receive("receive", msg.sender, msg.value);
    }

    fallback() external payable {
        revert Fallback("fallback", msg.sender, msg.value, msg.data);
    }

    /** @dev this function creates a new reward drop
    @param _claimStart. Unix timestamp for the claim start date 
    @param _claimEnd. Unix timestamp for the claim end date 
    @param _maxClaimPerWinner. Total tokens to distribute to each winner
    @param _maxWinners. Total winners in reward drop
    @param _description. Description of reward drop, for generating a human readable reference
    Only callable by admin. 
    Can be called when system and contract are unpaused.
    */
    function createRewardDrop(
        uint256 _claimStart,
        uint256 _claimEnd,
        uint256 _maxClaimPerWinner,
        uint256 _maxWinners,
        string calldata _description
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyRewardDropRole
    {
        if (
            claimStartDelay == 0 ||
            _claimStart - block.timestamp < claimStartDelay
        )
            revert InvalidClaimStartTime(
                _claimStart - block.timestamp,
                claimStartDelay
            );
        if (
            minimumClaimPeriod == 0 ||
            _claimEnd - _claimStart < minimumClaimPeriod
        )
            revert InvalidClaimEndTime(
                _claimEnd - _claimStart,
                minimumClaimPeriod
            );

        if (_maxClaimPerWinner > maximumClaimPerWinner)
            revert ExceedsMaxClaimPerWinnerCap(
                _maxClaimPerWinner,
                maximumClaimPerWinner
            );

        if (_maxWinners > maximumWinners)
            revert ExceedsMaxWinnersCap(_maxWinners, maximumWinners);

        if (
            _insufficientBalance(
                token.balanceOf(address(this)),
                grandTotal + (_maxClaimPerWinner * _maxWinners)
            )
        )
            revert InsufficientBalance(
                token.balanceOf(address(this)),
                grandTotal + (_maxClaimPerWinner * _maxWinners)
            );

        id++;

        RewardDrop memory newRewardDrop = _createRewardDrop(
            id,
            _claimStart,
            _claimEnd,
            _maxClaimPerWinner,
            _maxWinners,
            _description
        );

        rewardDrops[id] = newRewardDrop;
        grandTotal += (_maxClaimPerWinner * _maxWinners);

        emit NewRewardDrop(
            id,
            newRewardDrop.ref,
            newRewardDrop.maxClaimPerWinner,
            newRewardDrop.maxWinners,
            newRewardDrop.claimStart,
            newRewardDrop.claimEnd
        );
    }

    /** 
    @dev function to drop reward
    @param _id. The rewardDrop id 
    @param _winners. The list of winner accounts to distribute the tokens to
    Only callable by admin. 
    Can be called when system and contract are unpaused.
    Expiry date must have passed. 
    RewardDrop must not have been executed before. 
    Accounts length must be <= maxWinners
    Total amount for distribution must be less than contract's balance.
    This function loops through accounts and distributes the tokens
    Reward value is transferred from reward drop contract to the account.
    After rewards have been transferred, the state of reward drop is changed to executed. 
    */

    function rewardDrop(
        uint256 _id,
        address[] calldata _winners
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyRewardDropRole
        onlyActive(_id)
        claimExpired(_id)
    {
        if (_winners.length == 0) revert RewardDropEmpty(_id);

        _rewardDrop(_id, _winners, State.Executed);

        emit RewardDropState(_id, rewardDrops[_id].state);
    }

    /**
     * @dev This function allows exeucitve to set the claim start delay
     * @param _claimStartDelay. The claim start delay
     */

    function setClaimStartDelay(
        uint256 _claimStartDelay
    ) external virtual override onlyExecutive {
        claimStartDelay = _claimStartDelay;
        emit ClaimStartDelay(claimStartDelay);
    }

    /**
     * @dev This function allows exeucitve to set the claim end delay
     * @param _minimumClaimPeriod. The claim end delay
     */

    function setMinimumClaimPeriod(
        uint256 _minimumClaimPeriod
    ) external virtual override onlyExecutive {
        minimumClaimPeriod = _minimumClaimPeriod;
        emit MinimumClaimPeriod(minimumClaimPeriod);
    }

    /**
     * @dev This function allows executive to set the max claim per winner
     * @param _maximumClaimPerWinner. The max claim per winner
     */

    function setMaximumClaimPerWinner(
        uint256 _maximumClaimPerWinner
    ) external virtual override onlyExecutive {
        maximumClaimPerWinner = _maximumClaimPerWinner;
        emit MaximumClaimPerWinner(maximumClaimPerWinner);
    }

    /**
     * @dev This function allows exeucitve to set the max winners per drop
     * @param _maximumWinners. The max winners per drop
     */

    function setMaximumWinners(
        uint256 _maximumWinners
    ) external virtual override onlyExecutive {
        if (_maximumWinners > 70)
            revert MaximumWinnersExceeded(_maximumWinners, 70);
        maximumWinners = _maximumWinners;
        emit MaximumWinners(maximumWinners);
    }

    /**
     * @dev This function allows exeucitve to withdraw unclaimed tokens
     * @param amount. The amount to be withdrawn
     * @param recepient. The receipient address
     */
    function withdraw(
        uint256 amount,
        address recepient
    ) external virtual override onlyExecutive {
        require(recepient != address(0), "Boostplays: address(0) is forbidden");
        uint256 excess = token.balanceOf(address(this)) - grandTotal;

        if (amount > excess) revert WithdrawalExceedsExcess(amount, excess);

        token.safeTransfer(recepient, amount);
    }

    /**
     * @dev Updates an existing reward drop with the specified ID.
     * @param _id The ID of the reward drop to update.
     * @param _description A description of the reward drop.
     * @param _claimStart The timestamp at which participants can start claiming rewards.
     * @param _claimEnd The timestamp at which the reward drop will end.
     * @param _maxClaimPerWinner The maximum amount of rewards each winner can claim.
     * @param _maxWinners The maximum number of winners for the reward drop.
     * Requirements:
     * - The caller must have the `REWARD_DROP_ROLE` role.
     * - The reward drop must not have already started.
     * - The `_claimStart` time must be after the current time plus the `claimStartDelay`.
     * - The `_claimEnd` time must be at least `minimumClaimPeriod` seconds after the `_claimStart` time.
     * - The `_maxClaimPerWinner` must be less than or equal to `maximumClaimPerWinner`.
     * - The `_maxWinners` must be less than or equal to `maximumWinners`.
     * - The contract must have sufficient balance to cover the rewards.
     * Emits a `RewardDropUpdated` event with the updated reward drop information.
     */
    function updateRewardDrop(
        uint256 _id,
        string calldata _description,
        uint256 _claimStart,
        uint256 _claimEnd,
        uint256 _maxClaimPerWinner,
        uint256 _maxWinners
    ) external virtual onlyRewardDropRole {
        if (_id > id) revert NonExistentID();
        if (block.timestamp >= rewardDrops[_id].claimStart) {
            revert AirdropLive(_id);
        }

        if (
            claimStartDelay == 0 ||
            _claimStart - block.timestamp < claimStartDelay
        )
            revert InvalidClaimStartTime(
                _claimStart - block.timestamp,
                claimStartDelay
            );
        if (
            minimumClaimPeriod == 0 ||
            _claimEnd - _claimStart < minimumClaimPeriod
        )
            revert InvalidClaimEndTime(
                _claimEnd - _claimStart,
                minimumClaimPeriod
            );

        if (_maxClaimPerWinner > maximumClaimPerWinner)
            revert ExceedsMaxClaimPerWinnerCap(
                _maxClaimPerWinner,
                maximumClaimPerWinner
            );

        if (_maxWinners > maximumWinners)
            revert ExceedsMaxWinnersCap(_maxWinners, maximumWinners);

        grandTotal -= (rewardDrops[_id].maxClaimPerWinner *
            rewardDrops[_id].maxWinners);

        if (
            _insufficientBalance(
                token.balanceOf(address(this)),
                grandTotal + (_maxClaimPerWinner * _maxWinners)
            )
        )
            revert InsufficientBalance(
                token.balanceOf(address(this)),
                grandTotal + (_maxClaimPerWinner * _maxWinners)
            );
        grandTotal += (_maxClaimPerWinner * _maxWinners);
        rewardDrops[_id].ref = _generateRef(_id, _description);
        rewardDrops[_id].claimStart = _claimStart;
        rewardDrops[_id].claimEnd = _claimEnd;
        rewardDrops[_id].maxClaimPerWinner = _maxClaimPerWinner;
        rewardDrops[_id].maxWinners = _maxWinners;

        emit RewardDropUpdated(
            _id,
            rewardDrops[_id].ref,
            _claimStart,
            _claimEnd,
            _maxClaimPerWinner,
            _maxWinners
        );
    }

    /**
     * @notice Cancels a reward drop.
     * @dev This function can only be called by an address with the RewardDropRole.
     * @param _id The ID of the reward drop to cancel.
     *
     * Requirements:
     * - The reward drop must not be in the Cancelled state.
     *
     * Emits a {RewardDropState} event.
     */
    function cancelRewardDrop(
        uint256 _id
    ) external virtual override onlyRewardDropRole {
        if (_id > id) revert NonExistentID();
        if (rewardDrops[_id].state == State.Cancelled)
            revert InvalidRewardDropState(_id, rewardDrops[_id].state);

        grandTotal -= (rewardDrops[_id].maxClaimPerWinner *
            rewardDrops[_id].maxWinners);

        rewardDrops[_id].state = State.Cancelled;

        emit RewardDropState(_id, rewardDrops[_id].state);
    }

    /**
     * @dev function to pause airdrop only callable by admin
     */

    function pauseRewardDrop(
        uint256 _id
    ) external virtual override onlyRewardDropRole {
        if (
            rewardDrops[_id].state == State.Paused ||
            rewardDrops[_id].state == State.Cancelled ||
            rewardDrops[_id].state == State.Executed
        ) revert InvalidRewardDropState(_id, rewardDrops[_id].state);

        rewardDrops[_id].state = State.Paused;

        emit RewardDropState(_id, rewardDrops[_id].state);
    }

    /**
     * @dev function to unpause airdrop only callable by admin
     */

    function unpauseRewardDrop(
        uint256 _id
    ) external virtual override onlyRewardDropRole {
        if (
            rewardDrops[_id].state == State.Active ||
            rewardDrops[_id].state == State.Cancelled ||
            rewardDrops[_id].state == State.Executed
        ) revert InvalidRewardDropState(_id, rewardDrops[_id].state);

        rewardDrops[_id].state = State.Active;

        emit RewardDropState(_id, rewardDrops[_id].state);
    }

    /**
     * @dev function to pause contract only callable by admin
     */
    function pauseContract() external virtual override onlyRewardDropRole {
        _pause();
    }

    /**
     * @dev function to unpause contract only callable by admin
     */
    function unpauseContract() external virtual override onlyRewardDropRole {
        _unpause();
    }

    /** 
    @dev external function that returns reward drop data for given id. 
    @param _id. The id 
    */
    function getRewardDrop(
        uint256 _id
    ) external view virtual override returns (RewardDrop memory) {
        return rewardDrops[_id];
    }

    /** 
    @dev external function that returns the latest id
    */

    function getRewardDropCount()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return id;
    }

    /** @dev this function returns an paginated array of RewardDrop structs
    Id starts at 1.
    If there are no reward drops, it returns an empty array
    @param _pageLength. The number of pages
    @param _page. The page number to return data for
    @param _direction. Input is either 0 for directing left and 1 for directing right.
     */
    function getPaginatedRewardDrops(
        uint16 _pageLength,
        uint16 _page,
        uint8 _direction
    ) external view virtual override returns (RewardDrop[] memory) {
        require(
            _direction == 0 || _direction == 1,
            "RewardDrop: invalid direction input"
        );
        if (_page == 0) {
            require(
                _direction == 1,
                "RewardDrop: page 0 must have direction 1"
            );
        }
        RewardDrop[] memory dataArray = new RewardDrop[](id);
        RewardDrop memory datum;
        uint256 counter = 0;
        uint256 index;

        if (_page > 0) {
            index = _page * _pageLength + 1;
        } else {
            index = 1;
        }

        require(index <= id, "RewardDrop: index too high, reduce page length");

        uint256 length;

        if (id > 0) {
            if (_direction == 1) {
                length = index + _pageLength;

                for (uint256 i = index; i < length; i++) {
                    datum = rewardDrops[i];
                    dataArray[counter] = datum;
                    counter++;
                }
            } else {
                length = index - _pageLength;

                for (uint256 i = index - 1; i >= length; i--) {
                    datum = rewardDrops[i];
                    dataArray[counter] = datum;
                    counter++;
                }
            }
        }

        return dataArray;
    }

    /* ========== INTERNAL ========== */

    /**
     * @dev Transfers rewards to the specified winners for the reward drop with the specified ID and updates its state.
     * @param _id The ID of the reward drop to distribute rewards for.
     * @param _winners The addresses of the winners who will receive rewards.
     * @param _newState The new state to set the reward drop to.
     * Requirements:
     * - The `_winners` array length must not exceed the maximum number of winners for the reward drop.
     * - The total amount claimed by the reward drop must not exceed the maximum amount of rewards available.
     * - The contract must have sufficient balance to cover the rewards.
     * Emits a `RewardDropClaimed` event for each winner with the ID of the reward drop.
     */
    function _rewardDrop(
        uint256 _id,
        address[] calldata _winners,
        State _newState
    ) internal {
        if (_exceedsMaxWinners(_id, _winners))
            revert ExceedsMaxWinners(
                _id,
                _winners.length,
                rewardDrops[_id].maxWinners
            );

        rewardDrops[_id].totalClaimed += (rewardDrops[_id].maxClaimPerWinner *
            _winners.length);
        rewardDrops[_id].state = _newState;

        grandTotal -= (rewardDrops[_id].maxClaimPerWinner *
            rewardDrops[_id].maxWinners);

        for (uint256 i; i < _winners.length; i++) {
            token.safeTransfer(_winners[i], rewardDrops[_id].maxClaimPerWinner);
            emit RewardDropClaimed(_id, _winners[i]);
        }
    }

    /**
    @dev this is an internal function which returns true if the param lengths are not equal
    @param _winners. Array of account addresses
    */

    function _exceedsMaxWinners(
        uint256 _id,
        address[] calldata _winners
    ) internal view returns (bool notEqual) {
        return (_winners.length > rewardDrops[_id].maxWinners);
    }

    /** 
    @dev internal function returns true if the claim has expired. 
    @param _id. The id for RewardDrop
    */
    function _claimExpired(uint256 _id) internal view returns (bool expired) {
        return (block.timestamp > rewardDrops[_id].claimEnd);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
