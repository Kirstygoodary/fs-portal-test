// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libraries/VoteLib.sol";

/**
@title Vote contract
*/

abstract contract Vote {
    using VoteLib for *;

    /* ========== STATE VARIABLES ========== */

    /// stores voteData for proposal Id
    mapping(uint256 => VoteLib.VoteData) voteData;
    /// stored when user has voted for proposal Id
    mapping(uint256 => mapping(address => bool)) hasVoted;

    /* ========== EVENTS ========== */

    event TotalVotesForAgainst(
        uint256 indexed id,
        uint256 forVotes,
        uint256 againstVotes
    );
    event TotalVotesForAgainstAbstain(
        uint256 indexed id,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes
    );
    event TotalVotesMultiChoice(
        uint256 indexed id,
        uint256 aVotes,
        uint256 bVotes,
        uint256 cVotes,
        uint256 abstainVotes
    );
    event NewVote(
        uint256 indexed id,
        address indexed voter,
        VoteLib.Vote vote,
        uint256 weight
    );

    /* ========== ERROR STATEMENTS ========== */

    error InvalidVote(Vote _vote);

    /* ========== INTERNAL ========== */

    /** 
    @dev internal function which stores votes for ForAgainst proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
     */
    function _storeVoteForAgainst(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteForAgainst(_vote, _weight);

        emit TotalVotesForAgainst(_id, data.forVotes, data.againstVotes);
    }

    /**
    @dev internal function which stores votes for ForAgainstAbstain proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
     */
    function _storeVoteForAgainstAbstain(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteForAgainstAbstain(_vote, _weight);

        emit TotalVotesForAgainstAbstain(
            _id,
            data.forVotes,
            data.againstVotes,
            data.abstainVotes
        );
    }

    /**
    @dev internal function which stores votes for MultiChoice proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
     */
    function _storeVoteMultiChoice(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteMultiChoice(_vote, _weight);

        emit TotalVotesMultiChoice(
            _id,
            data.aVotes,
            data.bVotes,
            data.cVotes,
            data.abstainVotes
        );
    }

    /**
    @dev internal function which stores bool to show user has voted
    @param _id. The vote data id
    @param _voter. The voter's address
     */

    function _storeHasVoted(uint256 _id, address _voter) internal {
        hasVoted[_id][_voter] = true;
    }

    /** @dev this function returns the outcome for for against proposals */

    function _getOutcomeForAgainst(
        uint256 _id
    ) internal view returns (string memory outcome) {
        VoteLib.VoteData memory data = voteData[_id];

        return data.getOutcomeForAgainst();
    }

    /** @dev this function returns the outcome for multichoice proposals */

    function _getOutcomeMultiChoice(
        uint256 _id
    ) internal view returns (string memory outcome) {
        VoteLib.VoteData memory data = voteData[_id];
        return data.getOutcomeMultiChoice();
    }

    /** 
    @dev internal function which returns the total votes for the given proposal
    @param _id. The vote data id.
     */
    function _getTotalVoters(uint256 _id) internal view returns (uint256) {
        return voteData[_id].totalVoters;
    }

    /**
    @dev internal function that returns vote data 
    @param _id. Vote data id
    */

    function _getVoteData(
        uint256 _id
    ) internal view returns (VoteLib.VoteData memory) {
        return voteData[_id];
    }

    /**
    @dev internal function that returns all vote data 
    @param _id. The latest proposal id.
    */
    function _getAllVoteData(
        uint256 _id
    ) internal view returns (VoteLib.VoteData[] memory) {
        VoteLib.VoteData[] memory voteDataArray = new VoteLib.VoteData[](_id);
        VoteLib.VoteData memory voteDatum;
        uint256 numberItems = _id;
        uint256 counter = 0;

        if (numberItems > 0) {
            for (uint256 i = 1; i <= numberItems; ) {
                voteDatum = voteData[i];
                voteDataArray[counter] = voteDatum;
                unchecked {
                    ++i;
                    ++counter;
                }
            }
        }
        return voteDataArray;
    }
}
