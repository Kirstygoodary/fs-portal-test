import { ethers, upgrades } from "hardhat";

async function main() {

	const deployer = await ethers.getSigner('0xB389a9aA1B44f527fE0401C73C7C8917ce9ADA07')

	// const provider = new ethers.providers.JsonRpcProvider('https://eth-goerli.g.alchemy.com/v2/Q7O028FyF9m6xw3n09Ucaw8Rlm9StUqn')


	// const deployer = new ethers.Wallet('0x424729f525ac2e1c5e37bde0bc8bf0e682a152375d50100a39b9815d3a5b2866', provider);


	// console.log(
	// "Deploying Token contract with the account:",
	// deployer.address
	// );

	// const SafeToken = await ethers.getContractFactory("SafeToken")
	
	// const safeToken = await SafeToken.deploy();

	// await safeToken.depl

	const TOKEN = await ethers.getContractFactory("TOKEN", deployer);
	// access and pauser addresses taken from the latest build
	const token = await upgrades.deployProxy(TOKEN, ['0x924747217d46a012Af1eC4843b79d1992Ef943C7', '0xfDff5E14B25beCBD1bb5530114e98e1A563B299F', ethers.parseEther("10")]);

	await token.waitForDeployment();
	console.log("Token contract deployed at:", await token.getAddress());
  }

	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
