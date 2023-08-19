


import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");
import { Contract, Wallet } from "ethers";
import { Provider } from "@ethersproject/providers";
import { tokenAbi, factoryAbi, managerAbi, pauserAbi, rewardPoolAbi, boostAbi, accessAbi, governanceAbi, weightCalculatorAbi, stakingAbi } from "../helpers";
import { promises as fs } from "fs";
import SafeApiKit from "@safe-global/api-kit";
import {
  SafeTransactionDataPartial,
  SafeMultisigTransactionResponse,
} from "@safe-global/safe-core-sdk-types";
import Safe, { EthersAdapter } from "@safe-global/protocol-kit";
import { expect } from "chai";
import { executeGnosisSafeTx } from "../helpers";
require("dotenv").config();


async function main() {

  let provider = new ethers.providers.JsonRpcProvider(
    "https://eth-goerli.g.alchemy.com/v2/-sRSjnZS3Z27xu4YHwlqAjP86-pHE7uO"
  );
  let receipt: any;
  let tx: any;
  
  let ExecSdkOwner1: Safe;
  let ExecSdkOwner2: Safe;
  
  let exec: EthersAdapter;
  let admin: EthersAdapter;
  let service: SafeApiKit;
  
  let execSigner: Wallet = new ethers.Wallet(`${process.env.DEPLOYER_2}`, provider);
  let adminSigner: Wallet = new ethers.Wallet(`${process.env.ADMIN}`, provider);
  let voter1 = new Wallet(`0x${process.env.VOTER_1}`, provider)
  let voter2 = new Wallet(`0x${process.env.VOTER_2}`, provider)

  const vext = new Contract('0x2dd0849e27b78cb66E144A50105E785CFd815EAa', tokenAbi.abi, provider);

  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  exec = new EthersAdapter({
    ethers,
    signerOrProvider: execSigner,
  });
  admin = new EthersAdapter({
    ethers,
    signerOrProvider: adminSigner,
  });
  
  const txServiceUrl = "https://safe-transaction-goerli.safe.global";
  const safeservice = new SafeApiKit({ txServiceUrl, ethAdapter: exec })

  console.log("Creating Gnosis safes for signers...");
    // Create Safe instance
    ExecSdkOwner1 = await Safe.create({
      ethAdapter: exec,
      safeAddress: "0x71120E01AF18a7B51Be30da193ee0586b4f7F068",
    });
    ExecSdkOwner2 = await Safe.create({
      ethAdapter: admin,
      safeAddress: "0x71120E01AF18a7B51Be30da193ee0586b4f7F068",
    });
    
    console.log("Set up complete");

	// const FxERC20ChildTunnel = await hre.ethers.getContractFactory("FxERC20ChildTunnel");
  // const fxERC20ChildTunnel = await FxERC20ChildTunnel.deploy('0xCf73231F28B7331BBe3124B907840A94851f9f11', '0x3b8Ff2D4C1f1407D698b7cbF2073916BA071A539');
  // console.log("FxERC20ChildTunnel deployed to:", await fxERC20ChildTunnel.getAddress());

  // const token = await ethers.getContractAt('TOKEN', '0x2dd0849e27b78cb66E144A50105E785CFd815EAa')

  // const tx = await token.mint(
  //   '0xB389a9aA1B44f527fE0401C73C7C8917ce9ADA07', ethers.parseEther("10")
  // );
  // console.log(await tx);

  // // await setFxRootTunnel.wait();
  // console.log("minted");

  /**
   * On the FxERC20RootTunnel contract, set the setFxChildTunnel function. This should be done with the FxERC20ChildTunnel contract address from step 5s
   */
  }


	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
