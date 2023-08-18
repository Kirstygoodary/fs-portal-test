// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./VoteLib.sol";

/**
@title WeightCalculatorLib library
@notice this is a library for updating the pre normalised weight, calculating calculating the normalised weight and returning the proposal's outcome
@author MDRxTech
 */

library WeightCalculatorLib {
    /* ========== TYPE DECLARATIONS ========== */

    struct VoteWeightData {
        mapping(VoteLib.Vote => mapping(uint256 => VoteWeight)) voteWeight;
        mapping(VoteLib.Vote => uint256) totalVotersPerVote;
        mapping(VoteLib.Vote => uint256) normalisedWeight;
        uint256 totalPreNormalisedWeight;
        bool calculationsComplete;
    }

    struct VoteWeight {
        address voter;
        uint256 preNormalisedWeight;
        uint256 normalisedWeight;
    }
    /* ========== CONSTANTS ========== */

    /// Rebalancing factor to assist with division
    uint256 constant BPS = 1e18;

    /* ========== FUNCTIONS ========== */

    /**
    @dev this function stores the pre normalised weight for the given voter and updates the total weight
    */

    function storeVotersPreNormalisedWeight(
        VoteWeightData storage data,
        VoteLib.Vote vote,
        uint256 weight,
        address voter
    ) internal returns (VoteWeightData storage) {
        data.totalVotersPerVote[vote]++;

        data.voteWeight[vote][data.totalVotersPerVote[vote]].voter = voter;

        data
        .voteWeight[vote][data.totalVotersPerVote[vote]]
            .preNormalisedWeight = weight;

        data.totalPreNormalisedWeight += weight;
        return data;
    }

    /**
    @dev this function calculates and stores the normalised weight, and updates the total normalised weight for the vote
    */

    function storeNormalisedWeight(
        VoteWeightData storage data,
        VoteLib.Vote _vote,
        uint256 _index
    ) internal {
        uint256 normalisedWeight = (data
        .voteWeight[_vote][_index].preNormalisedWeight * BPS) /
            data.totalPreNormalisedWeight;

        data.voteWeight[_vote][_index].normalisedWeight = normalisedWeight;

        data.normalisedWeight[_vote] += normalisedWeight;
    }
}
