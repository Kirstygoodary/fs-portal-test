import { ethers, upgrades } from "hardhat";
import { FxERC20 } from '../typechain-types/contracts/core/token/FxERC20';
import { fxErc20 } from '../fx-values';
const hre = require("hardhat");


async function main() {

	const deployer = await ethers.getSigner('0xB389a9aA1B44f527fE0401C73C7C8917ce9ADA07')

	const FxERC20 = await hre.ethers.getContractFactory("FxERC20");
  const fxErc20 = await FxERC20.deploy();
  console.log("FxERC20 deployed to:", await fxErc20.getAddress());


	// const FxERC20 = await ethers.getContractFactory("FxERC20");
	// // access and pauser addresses taken from the latest build
	// const fxErc20 = await upgrades.deployProxy(FxERC20, ['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', "RacingToken", "TOKEN", 18]);

	// await fxErc20.waitForDeployment();
	// console.log("FxERC20 contract deployed at:", await fxErc20.getAddress());
  }

	/**
	 *    address fxManager_, // the address of the FxPortal contract, however set to 0x0
        address connectedToken_, // address of the token on the root network Goerli/Ethereum,  however set to 0x0
        string memory name_, // "RacingToken", 
        string memory symbol_, // "TOKEN"
        uint8 decimals_ // 18
	 */

	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
