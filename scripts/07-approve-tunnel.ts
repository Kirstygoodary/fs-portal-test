

import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");
import { Contract, Wallet } from "ethers";
import { tokenAbi, factoryAbi, managerAbi, pauserAbi, rewardPoolAbi, boostAbi, accessAbi, governanceAbi, weightCalculatorAbi, stakingAbi } from "../helpers";



async function main() {

  let provider = new ethers.providers.JsonRpcProvider(
    "https://eth-goerli.g.alchemy.com/v2/-sRSjnZS3Z27xu4YHwlqAjP86-pHE7uO"
  );
  let deployer: Wallet = new ethers.Wallet(`${process.env.DEPLOYER_2}`, provider);

  const vext = new Contract('0x2dd0849e27b78cb66E144A50105E785CFd815EAa', tokenAbi.abi, provider);

  const tx = await vext.connect(deployer).approve('0x2EEe18660B88248951285B3831D0F04149647d91', ethers.utils.parseEther('2'))

  const receipt = await tx.wait(1);

  console.log(receipt)

  // approving the fxErc20Tunnel address the withdraw funds to bridge to Polygon
  }


	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
