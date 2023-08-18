import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";
import * as values from "../fx-values";
async function main() {

	const [deployer, executive, admin, superAdmin, emergency] = await ethers.getSigners();

	console.log(
	"Deploying Token contract with the account:",
	deployer.address
	);

	// console.log("Account balance:", (await deployer.getBalance()).toString());

	const FxERC20 = await ethers.getContractFactory("FxERC20");
	const fxErc20 = await FxERC20.deploy(values.fxErc20.fxManager, values.fxErc20.connectedToken, values.fxErc20.name, values.fxErc20.symbol, values.fxErc20.decimals);
	console.log("Access contract deployed at:", fxErc20.address);
  }
