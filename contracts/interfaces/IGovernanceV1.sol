// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IGovernanceV1 is ERC165 {
    /* ========== TYPE DECLARATIONS ========== */

    struct ProposalData {
        string proposalRef;
        string url;
        uint256 start;
        uint256 end;
        uint256 created;
        ProposalState state;
        VoteModel voteModel;
        string category;
        bool isExecutable;
        bool paused;
        uint8 threshold;
        string outcome;
    }

    struct ExecutableData {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum Proposers {
        Execs,
        HighToken,
        Community
    }

    enum VoteModel {
        ForAgainst,
        ForAgainstAbstain,
        MultiChoice
    }

    /* ========== EVENTS ========== */

    event NewProposal(uint32 indexed id, ProposalData proposal);
    event NewQuorumThreshold(uint96 newThreshold);
    event NewQuorumMinimumAccounts(uint256 newThreshold);
    event NewProposerThreshold(uint256 newThreshold);
    event NewProposers(Proposers proposers);
    event ProposalCancelled(uint32 indexed id);
    event NewProposalState(uint32 indexed id, ProposalState proposalState);
    event ProposalOutcome(
        uint32 indexed id,
        string outcome,
        ProposalState proposalState
    );
    event PausedProposal(uint32 indexed id);
    event UnpausedProposal(uint32 indexed id);

    /* ========== REVERT STATEMENTS ========== */

    error ProposalExists(uint256 proposalHash);
    error AddressError();
    error VotingPeriodError(uint256 start, uint256 end);
    error InvalidProposalState(uint32 id, ProposalState state);
    error VoteCasted(uint32 id, address voter);
    error OutsideVotePeriod();
    error VoteNotEnded();
    error InvalidVoter();
    error ProposalPaused(uint32 id);
    error ProposalUnpaused(uint32 id);
    error HighTokenThresholdIsZero();
    error InvalidThreshold();
    error InvalidId(uint32 id);
    error ReducePageLength(uint32 id, uint16 pageLength, uint256 index);
    error ThresholdTooLow();

    /* ========== FUNCTIONS ========== */

    function proposeNonExecutable(
        string memory _description,
        string memory _url,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        uint8 _threshold
    ) external virtual;

    function setFlatMinimum(uint256 _newThreshold) external virtual;

    function setHighTokenThreshold(uint256 _newThreshold) external virtual;

    function setQuorumThreshold(uint8 _newThreshold) external virtual;

    function setProposers(Proposers _proposers) external virtual;

    function cancelProposal(uint32 _id) external virtual;

    function completeProposal(uint32 _id) external virtual;

    function getProposal(
        uint32 _id
    ) external view virtual returns (ProposalData memory);

    function getPaginatedProposals(
        uint16 _pageLength,
        uint16 _page,
        uint8 _direction
    ) external view virtual returns (ProposalData[] memory);

    function getProposalCount() external view virtual returns (uint32);

    function getProposalOutcome(uint32 _id) external virtual;

    function getTotalVoters(uint32 _id) external view virtual returns (uint256);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;

    function pauseProposal(uint32 _id) external virtual;

    function unpauseProposal(uint32 _id) external virtual;
}
