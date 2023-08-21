// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../core/security/AbstractSystemPause.sol";
import "../core/token/IFxERC20.sol";
import "../interfaces/IAccess.sol";

import "../rewards/staking/StakingManager.sol";
import "./Proposal.sol";
import "./Vote.sol";

contract GovernanceV1 is
    Proposal,
    Vote,
    AbstractSystemPause,
    Initializable,
    PausableUpgradeable
{
    /* ========== CONSTANTS ========== */

    /// Rebalancing factor to assist with division
    uint256 constant REBALANCING_FACTOR = 1000;

    /* ========== STATE VARIABLES ========== */

    /// Main access contract
    IAccess access;
    /// interface
    IFxERC20 token;
    /// Staking Manager
    StakingManager staking;
    Proposers public proposers;
    /// Mapping of ID => proposals
    mapping(uint256 => ProposalData) private _proposals;
    /// Mapping of ID hash => bool to indicate whether the proposal exists
    mapping(uint256 => bool) private _proposalExists;
    /// Flat minimum number of accounts that must have voted in order for a proposal to be accepted
    uint256 public flatMinimum;
    uint256 public highTokenThreshold;
    /// Counter for generating a human readable reference to the proposal
    uint32 id;
    /// Percentage threshold of total accounts that must have voted in order for a proposal to be accepted
    uint8 public quorumThreshold;

    /* ========== MODIFIERS ========== */

    /**
     @dev this modifier checks if the caller is a proposer 
     */

    modifier onlyProposers() {
        _onlyProposers();
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyExecutive() {
        _onlyExecutive();
        _;
    }

    /**
     @dev this modifier checks if the propossal is paused and reverts if true
     */

    modifier whenProposalNotPaused(uint32 _id) {
        _whenProposalNotPaused(_id);
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    function initialize(
        address _accessAddress,
        address _systemPauseAddress,
        address _tokenAddress,
        address _stakingManagerAddress,
        uint256 _flatMinimum,
        uint256 _highTokenThreshold,
        uint8 _quorumThreshold,
        Proposers _proposers
    ) public initializer {
        __Pausable_init();
        if (
            _tokenAddress == address(0) ||
            _accessAddress == address(0) ||
            _stakingManagerAddress == address(0) ||
            _systemPauseAddress == address(0)
        ) revert AddressError();

        if (_highTokenThreshold == 0) revert HighTokenThresholdIsZero();

        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        token = IFxERC20(_tokenAddress);
        staking = StakingManager(_stakingManagerAddress);
        flatMinimum = _flatMinimum;
        highTokenThreshold = _highTokenThreshold;
        quorumThreshold = _quorumThreshold;
        proposers = _proposers;
    }

    /* ========== EXTERNAL ========== */

    /**
    @dev this function creates a non executable proposal.
    @param _description. The description for proposal. It's purpose is to check if the proposal already exists
    @param _start. Unix timestamp for voting start
    @param _end. Unix timestamp for voting end
    @param _voteModel. The model for voting
    @param _category. The proposal's category. It's purpose is to create a human readable reference
    @param _threshold. The proposal's quorum threshold. The threshold is a % of total accounts that own TOKEN
    */
    function proposeNonExecutable(
        string memory _description,
        string memory _url,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        uint8 _threshold
    ) external virtual override onlyProposers whenNotPaused {
        if (_threshold == 0 || _threshold > 100) revert InvalidThreshold();
        if (_votingPeriodError(_start, _end))
            revert VotingPeriodError(_start, _end);

        uint256 proposalHash = uint256(keccak256(bytes(_description)));
        if (_proposalHashExists(proposalHash))
            revert ProposalExists(proposalHash);

        id++;

        string memory proposalRef = string(
            abi.encodePacked(Strings.toString(id), "_", _category)
        );

        ProposalData memory proposal = _proposal(
            proposalRef,
            _url,
            _start,
            _end,
            _voteModel,
            _category,
            false,
            _threshold
        );

        _proposals[id] = proposal;
        _proposalExists[proposalHash] = true;

        emit NewProposal(id, proposal);
    }

    /**
    @dev this function enables executive to cancel proposals
    @param _id. The id of the proposal
    Only callable by the executive account
    Callable when system and governance is unpaused
    */
    function cancelProposal(
        uint32 _id
    ) external virtual override onlyGovernance {
        ProposalData storage proposal = _proposals[_id];

        if (proposal.state != ProposalState.Pending)
            revert InvalidProposalState(_id, proposal.state);

        _changeProposalState(_id, ProposalState.Canceled);
    }

    /** 
    @dev this function is called when the user cast their vote during voting window.
    @param _id. The id hash for the proposal 
    @param _vote. The user's vote

    Callable when system and governance is unpaused
     */

    function castVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external whenNotPaused whenSystemNotPaused whenProposalNotPaused(_id) {
        if (_id > id) revert InvalidId(_id);
        if (token.delegates(msg.sender) == address(0)) revert InvalidVoter();
        if (hasVoted[_id][msg.sender]) revert VoteCasted(_id, msg.sender);

        uint256 current = block.timestamp;
        ProposalData storage proposal = _proposals[_id];

        if (proposal.state == ProposalState.Canceled)
            revert InvalidProposalState(_id, proposal.state);

        if (proposal.start > current || current > proposal.end)
            revert OutsideVotePeriod();

        if (proposal.state == ProposalState.Pending) {
            _changeProposalState(_id, ProposalState.Active);
        }

        uint256 weight = _getWeight(_id, msg.sender);

        if (weight < Math.sqrt(1e18)) revert InvalidVoter();

        _storeVote(_id, _vote, weight);
        _storeHasVoted(_id, msg.sender);

        emit NewVote(_id, msg.sender, _vote, weight);
    }

    /**
    @dev this function returns the proposal outcome after the voting window has closed. 
    @param _id. The id of the proposal

    Only admin can get the proposal outcome

    Callable when system and governance is unpaused

    This function checks whether the voting window has closed
    It checks that flat minimum has been exceeded
    It checks whether the total voters is above the proposal threshold

    It returns the proposal outcome and the proposal state. 
    */
    function getProposalOutcome(
        uint32 _id
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        whenProposalNotPaused(_id)
    {
        ProposalData storage proposal = _proposals[_id];
        if (
            proposal.state == ProposalState.Succeeded ||
            proposal.state == ProposalState.Defeated
        ) revert InvalidProposalState(_id, proposal.state);

        if (
            proposal.state == ProposalState.Pending &&
            block.timestamp >= proposal.end
        ) {
            _changeProposalState(_id, ProposalState.Active);
        }

        _checkProposalState(_id);
        uint256 totalVoters = _getTotalVoters(_id);
        uint256 totalAccounts = token.getTotalAccounts();
        string memory outcome;

        if (totalVoters < flatMinimum) {
            outcome = "Flat minimum not reached";
            _changeProposalState(_id, ProposalState.Defeated);
        } else if (totalVoters * 100 < quorumThreshold * totalAccounts) {
            outcome = "Quorum threshold not reached";
            _changeProposalState(_id, ProposalState.Defeated);
        } else if (totalVoters * 100 < proposal.threshold * totalAccounts) {
            outcome = "Total voters below threshold";
            _changeProposalState(_id, ProposalState.Defeated);
        } else {
            outcome = _getOutcome(_id, _proposals[_id].voteModel);
        }

        _storeOutcome(_id, outcome);
        keccak256(abi.encodePacked(outcome)) ==
            keccak256(abi.encodePacked("Succeeded"))
            ? _changeProposalState(_id, ProposalState.Succeeded)
            : _changeProposalState(_id, ProposalState.Defeated);
        emit ProposalOutcome(_id, proposal.outcome, proposal.state);
    }

    /** 
    @dev this functions is called by admin when the proposal has been completed
    @param _id. The proposal's id

    Callable when system and governance is unpaused
     */

    function completeProposal(
        uint32 _id
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        whenProposalNotPaused(_id)
        onlyGovernance
    {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.state != ProposalState.Succeeded)
            revert InvalidProposalState(_id, proposal.state);

        _changeProposalState(_id, ProposalState.Executed);
    }

    /**
    @dev this function sets the quorum minimum number of accounts
    @param _newThreshold. The new minimum number of accounts

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setFlatMinimum(
        uint256 _newThreshold
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyExecutive
    {
        flatMinimum = _newThreshold;

        emit NewQuorumMinimumAccounts(flatMinimum);
    }

    /**
    @dev this function sets the minimum tokens a TOKEN holder should hold to make a proposal
    @param _newThreshold. The amount in TOKEN that a user should own in order to make a proposal

    _newThreshold is converted to wei internally. 

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setHighTokenThreshold(
        uint256 _newThreshold
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyExecutive
    {
        if (_newThreshold < 1e18) revert ThresholdTooLow();
        highTokenThreshold = _newThreshold;
        emit NewProposerThreshold(highTokenThreshold);
    }

    /**
    @dev this function enables executive to change proposers
    @param _proposers. The new category of proposers allowed to make proposals

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setProposers(
        Proposers _proposers
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyGovernance
    {
        if (_proposers == Proposers.HighToken && highTokenThreshold == 0)
            revert HighTokenThresholdIsZero();

        proposers = _proposers;
        emit NewProposers(_proposers);
    }

    /** 
    @dev this function sets the quorum % threshold for all proposals.
    @param _newThreshold. The new global threshold that all proposal must meet in order for a proposal to pass.

    Only callable by executive. 
    Callable when system and governance is unpaused

    It checks that _newThreshold is a valid input and that it is not below the flat minimum.
     */

    function setQuorumThreshold(
        uint8 _newThreshold
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyExecutive
    {
        quorumThreshold = _newThreshold;
        emit NewQuorumThreshold(quorumThreshold);
    }

    /**
     * @dev function to pause contract only callable by admin
     */
    function pauseContract() external virtual override onlyGovernance {
        _pause();
    }

    /**
     * @dev function to unpause contract only callable by admin
     */
    function unpauseContract() external virtual override onlyGovernance {
        _unpause();
    }

    /**
     * @dev function to pause proposal by id
     */

    function pauseProposal(
        uint32 _id
    ) external virtual override onlyGovernance {
        if (_proposals[_id].paused) revert ProposalPaused(_id);

        _proposals[_id].paused = true;

        emit PausedProposal(_id);
    }

    /**
     * @dev function to pause proposal by id
     */

    function unpauseProposal(
        uint32 _id
    ) external virtual override onlyGovernance {
        if (!_proposals[_id].paused) revert ProposalUnpaused(_id);

        _proposals[_id].paused = false;

        emit UnpausedProposal(_id);
    }

    /**
    @dev this function returns the proposal core data for the given proposal id
    @param _id. The proposal id
    */
    function getProposal(
        uint32 _id
    ) external view virtual override returns (ProposalData memory) {
        ProposalData memory proposal = _proposals[_id];
        return proposal;
    }

    /**
    @dev this function returns an array of proposal data
    Id starts at 1.
    If there are no proposals, it returns an empty array
    */
    function getPaginatedProposals(
        uint16 _pageLength,
        uint16 _page,
        uint8 _direction
    ) external view virtual override returns (ProposalData[] memory) {
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
        ProposalData[] memory dataArray = new ProposalData[](id);
        ProposalData memory datum;
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
                    datum = _proposals[i];
                    dataArray[counter] = datum;
                    counter++;
                }
            } else {
                length = index - _pageLength;

                for (uint256 i = index - 1; i >= length; i--) {
                    datum = _proposals[i];
                    dataArray[counter] = datum;
                    counter++;
                }
            }
        }

        return dataArray;
    }

    /**
    @dev this function returns a uint256 code for whether the voter is eligible to vote
    0 = User not eligible. User has not delegated.
    1 = User not eligible. User delegated after the proposal was created.
    2 = User not eligible. User delegated before the proposal was created. User did not own enough TOKEN before proposal creation date.
    3 = User eligible. User delegated before proposal created and owned enough TOKEN to vote when the proposal was created.
    4 = not eligible. 
    */

    function isVoterEligible(
        uint32 _id,
        address _voter
    ) external view returns (uint256 code) {
        uint256 weight = _getWeight(_id, _voter);

        if (token.delegates(_voter) == address(0)) {
            code = 0;
        } else if (weight < Math.sqrt(1e18)) {
            uint32 firstCheckpointBlockNumber = token.getCheckpointBlockNumber(
                _voter,
                0
            );
            ProposalData memory proposal = _proposals[_id];

            if (firstCheckpointBlockNumber > proposal.created) {
                code = 1;
            } else code = 2;
        } else if (weight >= Math.sqrt(1e18)) {
            code = 3;
        } else {
            code = 4;
        }
    }

    /**
    @dev this fnuction returns the proposal count by returning id. 
    */

    function getProposalCount()
        external
        view
        virtual
        override
        returns (uint32)
    {
        return id;
    }

    /**
    @dev this function returns the total number of voters by id.
    @param _id. the proposal id.
    */
    function getTotalVoters(
        uint32 _id
    ) external view virtual override returns (uint256) {
        return _getTotalVoters(_id);
    }

    /* ========== PUBLIC ========== */

    /** 
    @dev this function returns the vote data by id
    @param _id. the proposal id.
    */

    function getVoteData(
        uint32 _id
    ) public view returns (VoteLib.VoteData memory) {
        return _getVoteData(_id);
    }

    /**
    @dev this function returns true if the account has voted for the given proposal id.
    @param _id. the proposal id.
    @param _account. The account address.
     */
    function hasAccountVoted(
        uint256 _id,
        address _account
    ) public view returns (bool) {
        return hasVoted[_id][_account];
    }

    /** 
    @dev this function returns the flat minimum 
    */

    function viewFlatMinimum() public view returns (uint256) {
        return flatMinimum;
    }

    /** 
    @dev this function returns the quorum threshold 
    */

    function viewQuorumThreshold() public view returns (uint8) {
        return quorumThreshold;
    }

    /** 
    @dev this function returns all vote data 
    */

    function getAllVoteData() public view returns (VoteLib.VoteData[] memory) {
        return _getAllVoteData(id);
    }

    function getWeightPublic(
        uint32 _proposalId,
        address _voterAddress
    ) external view returns (uint256) {
        return (_getWeight(_proposalId, _voterAddress));
    }

    /* ========== INTERNAL ========== */

    /**
     @dev this is an internal function which store's the proposal's outcome
    @param _id. The id of the proposal
    @param _outcome. The outcome of the proposal
     */

    function _storeOutcome(uint32 _id, string memory _outcome) internal {
        ProposalData storage proposal = _proposals[_id];
        proposal.outcome = _outcome;
    }

    /** 
    @dev internal function which calls the required count method depending on the Vote Model.
    @param _id. The id of the proposal
    @param _vote. The vote choice to store 
    @param _weight. The weight for the vote
    */

    function _storeVote(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.voteModel == VoteModel.ForAgainst) {
            _storeVoteForAgainst(_id, _vote, _weight);
        } else if (proposal.voteModel == VoteModel.ForAgainstAbstain) {
            _storeVoteForAgainstAbstain(_id, _vote, _weight);
        } else {
            _storeVoteMultiChoice(_id, _vote, _weight);
        }
    }

    /**
    @dev internal function to change the proposal's state
    @param _id. The proposal's id 
    @param _newState. The proposal's new state
     */
    function _changeProposalState(
        uint32 _id,
        ProposalState _newState
    ) internal {
        ProposalData storage proposal = _proposals[_id];
        proposal.state = _newState;

        emit NewProposalState(_id, proposal.state);
    }

    /**
    @dev internal function to check that the proposal is ready for preparing the outcome
    @param _id. The proposal's id 
     */

    function _checkProposalState(uint32 _id) internal view {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.state != ProposalState.Active)
            revert InvalidProposalState(_id, proposal.state);

        if (block.timestamp <= proposal.end) revert VoteNotEnded();
    }

    /**
    @dev this is an internal function that checks for any inconsistencies in the voting start and end date.
    @param _start. The proposed voting start time 
    @param _end. The proposed voting end time

    It checks that the start time and end time are in the future. 
    It checks that the start time is greater than the end time
     */
    function _votingPeriodError(
        uint256 _start,
        uint256 _end
    ) internal virtual returns (bool) {
        uint256 current = block.timestamp;
        return (_start <= current || _end <= current || _end <= _start);
    }

    /**
    @dev this is an internal function which returns true if the proposal hash already exists 
    @param _proposalHash. The proposal hash for the proposed proposal
     */
    function _proposalHashExists(
        uint256 _proposalHash
    ) internal virtual returns (bool) {
        return _proposalExists[_proposalHash];
    }

    /**
     @dev this is an internal function which returns the proposal's outcome as a 
     string for a more detailed explanation of the outcome
    @param _id. The id of the proposal
     */
    function _getOutcome(
        uint32 _id,
        VoteModel _voteModel
    ) internal view returns (string memory outcome) {
        if (
            _voteModel == VoteModel.ForAgainst ||
            _voteModel == VoteModel.ForAgainstAbstain
        ) {
            outcome = _getOutcomeForAgainst(_id);
            (_id);
        } else {
            outcome = _getOutcomeMultiChoice(_id);
        }

        return outcome;
    }

    /**
    @dev internal function which returns the weight. The weight is the square root of the voter's balance at the point of proposal's creation (blocknumber creation).
    @param _id. The id for the proposal
    @param _voter. The voter's account
    @return uint256. The weight
    */
    function _getWeight(
        uint32 _id,
        address _voter
    ) internal view returns (uint256) {
        ProposalData memory proposal = _proposals[_id];
        uint256 checkpoint = proposal.created;

        uint256 weight = Math.sqrt(
            ((token.getProposalVotes(_voter, checkpoint)) +
                staking.getUserBalanceAtBlockNumber(_voter, checkpoint))
        );
        return weight;
    }

    /**
    @dev this is an internal function which reverts if the caller is not a valid proposer
    
    SuperAdmin are not authorised to make proposals. 

    It accounts for staked and unstaked balances. 

    Executive and Admin are able to make proposals regardless of eligible Proposers. 

     */
    function _onlyProposers() internal view {
        if (proposers == Proposers.Execs) {
            require(_onlyAdmin(), "Unauthorised");
        } else if (proposers == Proposers.HighToken) {
            require(
                (token.balanceOf(msg.sender) +
                    staking.getUserBalanceAtBlockNumber(
                        msg.sender,
                        block.number
                    )) >=
                    highTokenThreshold ||
                    _onlyAdmin(),
                "Unauthorised"
            );
        } else if (proposers == Proposers.Community) {
            require(
                (token.balanceOf(msg.sender) +
                    staking.getUserBalanceAtBlockNumber(
                        msg.sender,
                        block.number
                    )) >
                    1e18 ||
                    _onlyAdmin(),
                "Unauthorised"
            );
        }
    }

    /**
    @dev internal function to check whether the caller is admin
     */

    function _onlyAdmin() internal view returns (bool) {
        return (access.userHasRole(access.executive(), msg.sender) ||
            access.userHasRole(access.admin(), msg.sender) ||
            access.userHasRole(access.governanceRole(), msg.sender));
    }

    function _onlyGovernance() internal view {
        access.onlyGovernanceRole(msg.sender);
    }

    function _onlyExecutive() internal view {
        require(
            access.userHasRole(access.executive(), msg.sender),
            "Governance: access forbidden"
        );
    }

    function _whenProposalNotPaused(uint32 _id) internal view {
        if (_proposals[_id].paused) revert ProposalPaused(_id);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
