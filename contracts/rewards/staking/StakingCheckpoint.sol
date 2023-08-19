// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/utils/Votes.sol)
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Checkpoints.sol";

abstract contract StakingCheckpoint {
    using Checkpoints for Checkpoints.History;

    /* ========== STATE VARIABLES ========== */

    mapping(address => Checkpoints.History) private _stakeCheckpoints;

    /* ========== INTERNAL ========== */

    /**
     * @dev Create a staking snapshot.
     */
    function _addCheckpoint(
        address account,
        uint256 amount,
        uint256 blockNumber
    ) internal {
        uint32 _blockNumber = SafeCast.toUint32(blockNumber);
        uint224 _amount = SafeCast.toUint224(amount);
        _stakeCheckpoints[account]._checkpoints.push(
            Checkpoints.Checkpoint(_blockNumber, _amount)
        );
    }

    /**
     * @dev Returns the amount of token that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function _getPastCheckpoint(
        address account,
        uint256 blockNumber
    ) internal view virtual returns (uint256) {
        Checkpoints.History storage history = _stakeCheckpoints[account];

        uint256 pos;

        history._checkpoints.length == 1 &&
            history._checkpoints[0]._blockNumber > blockNumber
            ? pos = 0
            : pos = _stakeCheckpoints[account].getAtProbablyRecentBlock(
            blockNumber
        );

        return pos;
    }
}
