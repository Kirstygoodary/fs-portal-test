// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

import './IPoolState.sol';

abstract contract IRace is IPoolState {
    

    struct PoolInitiator {
        string _name;
        string _type;
        string _poolDescription;
        string _url;
        uint256 interestRateInBasisPoints;
        uint256 waitingRoomOpenDate;
        uint256 raceStartDate;
        uint256 raceEndDate;
        uint256 minimumStakePeruser;
        uint256 maximumStakePerUser;
        uint256 claimTimeAfterEndtime;
        uint256 maximumNumberOfStakers;
        uint256 maximumInterestRateInBasisPoints;
        uint256[] pitStopDates;
    }

    function _freeFromEmptyValues(
        PoolInitiator memory init
    ) internal pure returns (bool) {
        if (
            bytes(init._name).length == 0 ||
            bytes(init._type).length == 0 ||
            bytes(init._url).length == 0 ||
            init.interestRateInBasisPoints == 0 ||
            init.waitingRoomOpenDate == 0 ||
            init.raceStartDate == 0 ||
            init.raceEndDate == 0 ||
            init.minimumStakePeruser == 0 ||
            init.maximumStakePerUser == 0 ||
            init.maximumNumberOfStakers == 0 ||
            init.maximumInterestRateInBasisPoints == 0
        ) {
            return false;
        } else {
            return true;
        }
    }

    function _validateInputs(
        PoolInitiator memory init
    ) internal view returns (bool) {
        require(
            init.interestRateInBasisPoints > 0 &&
                init.interestRateInBasisPoints <=
                init.maximumInterestRateInBasisPoints,
            "interest rate must be > 0 & < maximumInterestRateInBasisPoints"
        );
        require(
            init.waitingRoomOpenDate > 0 &&
                init.waitingRoomOpenDate > block.timestamp,
            "waitingRoomOpenDate must be > 0 && > block.timestamp"
        );
        require(
            init.raceStartDate > 0 &&
                init.raceStartDate > init.waitingRoomOpenDate,
            "raceStartDate must be > 0 &&  waitingRoomOpenDate"
        );
        require(
            init.raceEndDate > 0 && init.raceEndDate > init.raceStartDate,
            "raceEndDate must be > 0 && raceStartDate"
        );
        require(init.minimumStakePeruser > 0, "minimum stake must be > 0");
        require(
            init.maximumStakePerUser > 0 &&
                init.maximumStakePerUser > init.minimumStakePeruser,
            "maximumStakePerUser must be > 0 && minimumStakePerUser"
        );
        require(
            _validatePitStopDates(init.pitStopDates),
            "invalid pit stop dates, pls fix!"
        );

        return true;
    }

    function _validateInputsPastWaitingRoomOpenTime(
        PoolInitiator memory init, PoolState memory pool
    ) internal pure returns (bool) {
        require(
            init.interestRateInBasisPoints > 0 &&
                init.interestRateInBasisPoints <=
                init.maximumInterestRateInBasisPoints,
            "interest rate must be > 0 & < maximumInterestRateInBasisPoints"
        );
      
        require(init.waitingRoomOpenDate == pool.waitingRoomOpenTime, "init.waitingRoomOpenDate must be the same");
        require(
            init.raceStartDate > 0 &&
                init.raceStartDate > init.waitingRoomOpenDate,
            "raceStartDate must be > 0 &&  waitingRoomOpenDate"
        );
        require(
            init.raceEndDate > 0 && init.raceEndDate > init.raceStartDate,
            "raceEndDate must be > 0 && raceStartDate"
        );
        require(init.minimumStakePeruser > 0, "minimum stake must be > 0");
        require(
            init.maximumStakePerUser > 0 &&
                init.maximumStakePerUser > init.minimumStakePeruser,
            "maximumStakePerUser must be > 0 && minimumStakePerUser"
        );
        require(
            _validatePitStopDates(init.pitStopDates),
            "invalid pit stop dates, pls fix!"
        );

        return true;
    }

    function _validPoolStateValues(
        PoolState memory pool
    ) internal pure returns (bool) {
        if (
            pool.raceStartTime == 0 ||
            pool.raceStartTime < pool.waitingRoomOpenTime ||
            pool.raceStartTime == pool.raceEndTime ||
            pool.raceEndTime == 0 ||
            pool.raceEndTime < pool.raceStartTime ||
            pool.minimumStakePerUser == 0 ||
            pool.minimumStakePerUser == pool.maximumStakePerUser ||
            pool.minimumStakePerUser > pool.maximumStakePerUser ||
            pool.poolInterestRateInBasisPoints == 0 ||
            pool.poolInterestRateInBasisPoints < 100 ||
            pool.poolInterestRateInBasisPoints > pool.maximumInterestRateInBasisPoints
        ) {
            return false;
        }

        return true;
    }

    function _validatePitStopDates(
        uint256[] memory arr
    ) internal pure returns (bool) {
        uint length = arr.length;
        if (length == 0 || length == 1) {
            return true;
        }

        for (uint256 i = 0; i < length - 1; i++) {
            if (arr[i] >= arr[i + 1]) {
                return false;
            }
        }

        return true;
    }

    function _validateIncreasingRaceTimes(
        uint256[3] memory arr
    ) internal pure returns (bool) {
        uint length = arr.length;
        for (uint256 i = 0; i < length - 1; i++) {
            if (arr[i] >= arr[i + 1]) {
                return false;
            }
        }

        return true;
    }

    function _validateRaceTimes(
        uint256[3] memory arr
    ) internal view returns (bool) {
        uint length = arr.length;
        for (uint256 i = 0; i < length; i++) {
            if (arr[i] < block.timestamp) {
                return false;
            }
        }
        return true;
    }

    function _validateIncreasingStakeValues(
        uint256[2] memory arr
    ) internal pure returns (bool) {
        return (arr[1] <= arr[0] ) ? false : true;
    }

    function _removeFromArray(address _val, address[] storage arr) internal {
        uint length = arr.length;
        for(uint256 i = 0; i < length ; i++){
            if(_val == arr[i]){
                arr[i] = arr[length - 1];
                arr.pop();
                break;
            }
        }
        
    }
}
