// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
@title VoteLib library
@notice this is a library for counting votes and return the proposal outcome
author MDRxTech
 */

library VoteLib {
    /* ========== TYPE DECLARATIONS ========== */
    struct VoteData {
        uint256 forVotes;
        uint256 againstVotes;
        uint256 aVotes;
        uint256 bVotes;
        uint256 cVotes;
        uint256 abstainVotes;
        uint256 totalVoters;
    }

    enum Vote {
        For,
        Against,
        A,
        B,
        C,
        Abstain
    }

    /* ========== ERROR STATEMENTS ========== */

    error InvalidVote(Vote _vote);

    /* ========== FUNCTIONS ========== */

    /** @dev this functions counts votes for ForAgainst Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteForAgainst(
        VoteData storage data,
        VoteLib.Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.For) {
            data.forVotes += weight;
        } else if (vote == Vote.Against) {
            data.againstVotes += weight;
        } else revert InvalidVote(vote);
        ++data.totalVoters;
        return data;
    }

    /** @dev this functions counts votes for ForAgainstAbstain Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteForAgainstAbstain(
        VoteData storage data,
        Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.For) {
            data.forVotes += weight;
        } else if (vote == Vote.Against) {
            data.againstVotes += weight;
        } else if (vote == Vote.Abstain) {
            data.abstainVotes += weight;
        } else {
            revert InvalidVote(vote);
        }
        ++data.totalVoters;
        return data;
    }

    /** @dev this functions counts votes for MultiChoice Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteMultiChoice(
        VoteData storage data,
        Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.A) {
            data.aVotes += weight;
        } else if (vote == Vote.B) {
            data.bVotes += weight;
        } else if (vote == Vote.C) {
            data.cVotes += weight;
        } else if (vote == Vote.Abstain) {
            data.abstainVotes += weight;
        } else revert InvalidVote(vote);
        ++data.totalVoters;
        return data;
    }

    /** @dev this function returns the outcome for for against proposals */

    function getOutcomeForAgainst(
        VoteData memory data
    ) internal pure returns (string memory outcome) {
        (data.forVotes > data.againstVotes)
            ? outcome = "Succeeded"
            : outcome = "Defeated";
        if (data.forVotes == data.againstVotes) outcome = "Draw";

        return outcome;
    }

    /** @dev this function returns the outcome for multichoice proposals */

    function getOutcomeMultiChoice(
        VoteData memory data
    ) internal pure returns (string memory outcome) {
        uint256 winningVote;
        uint256 drawingVote;

        uint256[3] memory votes;

        votes[0] = data.aVotes;
        votes[1] = data.bVotes;
        votes[2] = data.cVotes;

        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] > winningVote) {
                winningVote = votes[i];
            } else if (votes[i] == winningVote) {
                drawingVote = votes[i];
            }
        }

        if (winningVote != 0 && winningVote != drawingVote) {
            outcome = "Succeeded";
        } else if (winningVote == drawingVote) {
            outcome = "Draw";
        } else outcome = "Defeated";

        return outcome;
    }
}
