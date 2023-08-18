// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/WeightCalculatorLib.sol";

abstract contract IWeightCalculator is ERC165 {
    function setGovernanceAddress(address _governance) external virtual;

    function calculateNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _startIndex,
        uint256 _endIndex
    ) external virtual;

    function storePreNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) external virtual;

    function getTotalVotersByVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual returns (uint256);

    function getVoteWeightDataForVoter(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _index
    ) external view virtual returns (WeightCalculatorLib.VoteWeight memory);

    function getNormalisedWeightForVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual returns (uint256);

    function getTotalVoteWeight(
        uint32 _id
    ) external view virtual returns (uint256);

    function calculationsComplete(uint32 _id) external virtual returns (bool);
}
