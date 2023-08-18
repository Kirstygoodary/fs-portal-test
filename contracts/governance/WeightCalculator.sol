// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../core/security/AbstractSystemPause.sol";
import "../interfaces/ISystemPause.sol";
import "../interfaces/IGovernanceV1.sol";
import "../interfaces/IAccess.sol";
import "../interfaces/IWeightCalculator.sol";
import "../libraries/WeightCalculatorLib.sol";
import "../libraries/VoteLib.sol";

/**
@title WeightCalculator contract
@notice this contract stores pre normalised vote weight, calculates and stores the normalised weight for proposal votes 
@author MDRxTech
 */

contract WeightCalculator is IWeightCalculator, AbstractSystemPause {
    using WeightCalculatorLib for *;
    using VoteLib for *;

    /* ========== STATE VARIABLES ========== */

    IGovernanceV1 governance;
    // Access contract
    IAccess access;
    /// System pause contract
    ISystemPause systemPause;

    //mapping of id to vote weight data
    mapping(uint32 => WeightCalculatorLib.VoteWeightData) voteWeightData;

    /* ========== EVENTS ========== */

    event VotersNormalisedVoteWeight(
        uint32 id,
        address indexed voter,
        uint256 normalisedWeight
    );

    event NormalisedWeightCalculationComplete(uint32 _id);
    event LatestTotalWeight(uint32 id, uint256 weight);
    event VotersPreNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address indexed _voter,
        uint256 index
    );
    event GovernanceAddress(address _governanceAddress);

    /* ========== REVERT STATEMENTS ========== */

    error InvalidAddress();
    error NormalisedWeightHasBeenUpdated(
        address voter,
        uint256 normalisedWeight
    );

    /* ========== MODIFIERS ========== */

    /**
     @dev only callable by the Governance contract
     */

    modifier onlyGovernanceContract() {
        require(
            address(governance) != address(0),
            "WeightCalculator: please update WeightCalculator with the governance address"
        );
        require(
            msg.sender == address(governance),
            "WeightCalculator: unauthorised access"
        );
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyGovernanceRole() {
        access.onlyGovernanceRole(msg.sender);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _access, address _systemPause) {
        access = IAccess(_access);
        systemPause = ISystemPause(_systemPause);
    }

    /* ========== EXTERNAL ========== */

    function setGovernanceAddress(
        address _governance
    ) external virtual override onlyGovernanceRole {
        if (_governance == address(0)) revert InvalidAddress();
        governance = IGovernanceV1(_governance);

        emit GovernanceAddress(_governance);
    }

    /**
     @dev this function will store the voters vote weight after voter has casted their vote
     @param _id. The id for vote weight data 
     @param _vote. The voter's vote choice 
     @param _weight. The voter's vote weight 
     @param _voter. The voter's address
     */

    function storePreNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) external virtual override whenSystemNotPaused onlyGovernanceContract {
        WeightCalculatorLib.VoteWeightData storage data = voteWeightData[_id];
        data.storeVotersPreNormalisedWeight(_vote, _weight, _voter);

        emit VotersPreNormalisedWeight(
            _id,
            _vote,
            _weight,
            _voter,
            data.totalVotersPerVote[_vote]
        );
    }

    /**
     @dev this function will store the voters vote weight after voter has casted their vote
     @param _id. The id for vote weight data 
     @param _vote. The voter's vote choice 
     @param _startIndex. The start index
     @param _endIndex. The end index
     */

    function calculateNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _startIndex,
        uint256 _endIndex
    ) external virtual override whenSystemNotPaused onlyGovernanceContract {
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            _calculateNormalisedWeight(_id, _vote, i);
            emit VotersNormalisedVoteWeight(
                _id,
                voteWeightData[_id].voteWeight[_vote][i].voter,
                voteWeightData[_id].voteWeight[_vote][i].normalisedWeight
            );
        }
    }

    /** 
    @dev this function returns the total number of voters for a given vote 
    @param _id. the proposal id.
    @param _vote. The vote to return the total voters for.
    */

    function getTotalVotersByVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual override returns (uint256) {
        return voteWeightData[_id].totalVotersPerVote[_vote];
    }

    /** 
    @dev this function returns the vote weight data for a voter
    @param _id. the id.
    @param _vote. The voter's vote choice 
    @param _index. The voter's index
    */

    function getVoteWeightDataForVoter(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _index
    )
        external
        view
        virtual
        override
        returns (WeightCalculatorLib.VoteWeight memory)
    {
        return voteWeightData[_id].voteWeight[_vote][_index];
    }

    function getTotalVoteWeight(
        uint32 _id
    ) external view virtual override returns (uint256) {
        return voteWeightData[_id].totalPreNormalisedWeight;
    }

    /** 
    @dev this function returns the total normalised weight for a vote
    @param _id. the id.
    @param _vote. The vote to return the normalised weight for
    */

    function getNormalisedWeightForVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual override returns (uint256) {
        return voteWeightData[_id].normalisedWeight[_vote];
    }

    /** 
    @dev this function returns true if the normalised calculations are completed
    @param _id. the id.
    */

    function calculationsComplete(
        uint32 _id
    )
        external
        virtual
        override
        whenSystemNotPaused
        onlyGovernanceContract
        returns (bool)
    {
        return voteWeightData[_id].calculationsComplete;
    }

    /* ========== INTERNAL ========== */

    /**
    @dev internal function to calculate and store the user's normalised vote weight and update the total weight for the given vote.
    @param _id. The vote data id
    @param _vote. The vote 
    @param _index. The index to access pre normalised weight
     */

    function _calculateNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _index
    ) internal {
        if (voteWeightData[_id].voteWeight[_vote][_index].normalisedWeight > 0)
            revert NormalisedWeightHasBeenUpdated(
                voteWeightData[_id].voteWeight[_vote][_index].voter,
                voteWeightData[_id].voteWeight[_vote][_index].normalisedWeight
            );

        WeightCalculatorLib.VoteWeightData storage data = voteWeightData[_id];

        data.storeNormalisedWeight(_vote, _index);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
