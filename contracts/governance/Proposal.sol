// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IGovernanceV1.sol";

/**
@title Proposal contract
*/

abstract contract Proposal is IGovernanceV1 {
    /**
    @dev internal function which stores and returns a new proposal
    @return ProposalData struct 
     */
    function _proposal(
        string memory _proposalRef,
        string memory _url,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        bool _isExecutable,
        uint8 _threshold
    ) internal view returns (ProposalData memory) {
        ProposalData memory proposal = ProposalData(
            _proposalRef,
            _url,
            _start,
            _end,
            block.number,
            ProposalState.Pending,
            _voteModel,
            _category,
            _isExecutable,
            false,
            _threshold,
            ""
        );

        return proposal;
    }
}
