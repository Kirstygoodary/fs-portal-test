

import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");


async function main() {

	// const FxERC20ChildTunnel = await hre.ethers.getContractFactory("FxERC20ChildTunnel");
  // const fxERC20ChildTunnel = await FxERC20ChildTunnel.deploy('0xCf73231F28B7331BBe3124B907840A94851f9f11', '0x3b8Ff2D4C1f1407D698b7cbF2073916BA071A539');
  // console.log("FxERC20ChildTunnel deployed to:", await fxERC20ChildTunnel.getAddress());

  // const fxERC20ChildTunnel = await ethers.getContractAt('FxERC20ChildTunnel', '0xaC6F975289Bc19ED65F02712FB75737E9cf097C2')

  // const setFxRootTunnel = await fxERC20ChildTunnel.setFxRootTunnel(
  //   '0x2EEe18660B88248951285B3831D0F04149647d91'
  // );
  // console.log(setFxRootTunnel);
  // // await setFxRootTunnel.wait();
  // console.log("setFxRootTunnet set");

  /**
   * On the FxERC20ChildTunnel contract (step 5), set the setFxRootTunnel function. This should be done with the FxERC20RootTunnel contract address from step 4
   */


  }

  /**
   *    _fxChild : 0xCf73231F28B7331BBe3124B907840A94851f9f11
   *    _tokenTemplate : _fxERC20Token : FxERC20 address (address of FxERC20 template on Mumbai) 
   */


	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
