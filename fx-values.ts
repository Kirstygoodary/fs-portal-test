
import { ethers } from "hardhat";

export const fxErc20 = {
  fxManager: '',
  connectedToken: '', 
  name: 'RacingToken',
  symbol: 'TOKEN',
  decimals: 18
}

// export const access = {
//   executiveAddress: safes.executive === '' ? undefined : safes.executive,
//   adminAddress: safes.admin === '' ? undefined : safes.admin, 
//   emergencyAddress: safes.emergency === '' ? undefined : safes.emergency,
// }

// export const pauser = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress
// }

// export const vext = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress,
//   pauserAddress: addresses.pauserAddress === "" ? undefined : addresses.pauserAddress,
//   maxSupply: ethers.utils.parseEther("3000000000000"),
// }

// export const rewardDrop = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress,
//   pauserAddress: addresses.pauserAddress === "" ? undefined : addresses.pauserAddress,
//   tokenAddress: addresses.tokenAddress === "" ? undefined : addresses.tokenAddress,
//   claimStartDelay: 24 * 3600,
//   minimumClaimPeriod: 24 * 3600,
//   maximumClaimPerWinner: ethers.utils.parseEther("1"),
//   maximumWinners: 10
// } 

// export const boostPlays = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress,
//   pauserAddress: addresses.pauserAddress === "" ? undefined : addresses.pauserAddress,
//   tokenAddress: addresses.tokenAddress === "" ? undefined : addresses.tokenAddress,
// }

// export const weightCalculator = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress,
//   pauserAddress: addresses.pauserAddress === "" ? undefined : addresses.pauserAddress,
// } 

// export const stakingManager = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress,
//   pauserAddress: addresses.pauserAddress === "" ? undefined : addresses.pauserAddress,
// }

// export const stakingFactory = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress,
//   pauserAddress: addresses.pauserAddress === "" ? undefined : addresses.pauserAddress,
//   managerAddress: addresses.managerAddress === "" ? undefined : addresses.managerAddress, 
//   tokenAddress: addresses.tokenAddress === "" ? undefined : addresses.tokenAddress,
// }

// export const governance = {
//   accessControlAddress: addresses.accessControlAddress === "" ? undefined : addresses.accessControlAddress,
//   pauserAddress: addresses.pauserAddress === "" ? undefined : addresses.pauserAddress,
//   tokenAddress: addresses.tokenAddress === "" ? undefined : addresses.tokenAddress,
//   managerAddress: addresses.managerAddress === "" ? undefined : addresses.managerAddress, 
//   weightCalculatorAddress: addresses.weightCalculatorAddress === "" ? undefined : addresses.weightCalculatorAddress, 
//   flatMinimum: 5, 
//   highVextThreshold: ethers.utils.parseEther("100"), 
//   quorumPercentageThreshold: 2,
//   proposers: 0, // 0 = Veloce

//} 


