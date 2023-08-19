
import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");


async function main() {

	const FxERC20RootTunnel = await hre.ethers.getContractFactory("FxERC20RootTunnel");
  const fxERC20RootTunnel = await FxERC20RootTunnel.deploy('0x2890bA17EfE978480615e330ecB65333b880928e', '0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA', '0x0C2951180Da961c72c60871E6c4536A1053CDFf5');
  console.log("FxERC20RootTunnel deployed to:", await fxERC20RootTunnel.getAddress());
  }

  /**
   *    address _checkpointManager, // 0x2890bA17EfE978480615e330ecB65333b880928e
        address _fxRoot, // 0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA
        address _fxERC20Token // address of fxERC20Token on Goerli 0x0C2951180Da961c72c60871E6c4536A1053CDFf5
   */


	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
