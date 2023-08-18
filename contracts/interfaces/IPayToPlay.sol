// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

abstract contract IPayToPlay {
    /* ========== FUNCTIONS ========== */
    function userPayForGo(uint256 amount) external virtual;

    function getUserBalance(address addr) external virtual returns (uint256);

    function withdraw(uint256 amount, address to) external virtual;

    function setCostPerPlay(uint256 costPerPlay) external virtual;

    function getCostPerPlay() external virtual returns (uint256);
}
