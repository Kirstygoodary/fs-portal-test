import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";

async function main() {

	const [deployer, executive, admin, superAdmin, emergency] = await ethers.getSigners();

	console.log(
	"Deploying Token contract with the account:",
	deployer.address
	);

	const TOKEN = await ethers.getContractFactory("TOKEN");
	const token = await TOKEN.deploy(executive.address, admin.address, emergency.address, [superAdmin.address]);
	console.log("Token contract deployed at:", token.address);

  }
