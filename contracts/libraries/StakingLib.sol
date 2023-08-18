// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
@title SortingLib library
@notice this is a library for sorting dates into ascending order
@author https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
 */

library StakingLib {
    /* ========== FUNCTIONS ========== */

    /**
     * The function converts interest rates in basis points to interest rates in basis points per second.
     * @param _interestRateInBps The interest rate in basis points
     * @return The interest rate in basis points per second.
     */
    function getInterestRatePerSecondUnbalanced(
        uint _interestRateInBps
    ) internal pure returns (uint256) {
        uint totalSecsPerYear = 60 * 60 * 24 * 365;
        return ((10e18 * _interestRateInBps) / (totalSecsPerYear * 10000));
    }
}
