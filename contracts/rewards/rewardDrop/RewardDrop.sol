// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../interfaces/IRewardDrop.sol";

/**
@title RewardDrop contract
@notice this contract is an abstract contract for RewardDrop contracts. 
*/

abstract contract RewardDrop is IRewardDrop {
    /** 
    @dev this function stores the new reward drop data
    @param _id. The reward drop id. 
    @param _claimStart. The unix start time for claim period.
    @param _claimEnd. The unix end time for claim period.
    @param _totalClaimPerWinner. The total tokens to distribute to each winner
    @param _totalWinners. Total winners in the drop
    @param _description. Human readable description used to generate a human readable reference. 
    @return RewardDrop struct
    */

    function _createRewardDrop(
        uint256 _id,
        uint256 _claimStart,
        uint256 _claimEnd,
        uint256 _totalClaimPerWinner,
        uint256 _totalWinners,
        string calldata _description
    ) internal pure returns (RewardDrop memory) {
        string memory ref = _generateRef(_id, _description);

        RewardDrop memory newRewardDrop = RewardDrop(
            ref,
            _claimStart,
            _claimEnd,
            _totalClaimPerWinner,
            _totalWinners,
            0,
            State.Active
        );

        return newRewardDrop;
    }

    /**
    @dev this is an internal function which returns true if claim expiry is not a future timestamp
    @param _id. The id 
    @param _description. The reward drop's description
    */

    function _generateRef(
        uint256 _id,
        string calldata _description
    ) internal pure returns (string memory) {
        return
            string(abi.encodePacked(Strings.toString(_id), "_", _description));
    }

    /**
    @dev this is an internal function which returns true if contract does not have a sufficient balance for given value
    @param _balance. The contract's balance
    @param _value. The value
    */

    function _insufficientBalance(
        uint256 _balance,
        uint256 _value
    ) internal pure returns (bool insufficient) {
        return (_balance < _value);
    }
}
