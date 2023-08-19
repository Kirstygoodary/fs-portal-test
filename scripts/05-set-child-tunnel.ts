

import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");


async function main() {

	// const FxERC20ChildTunnel = await hre.ethers.getContractFactory("FxERC20ChildTunnel");
  // const fxERC20ChildTunnel = await FxERC20ChildTunnel.deploy('0xCf73231F28B7331BBe3124B907840A94851f9f11', '0x3b8Ff2D4C1f1407D698b7cbF2073916BA071A539');
  // console.log("FxERC20ChildTunnel deployed to:", await fxERC20ChildTunnel.getAddress());

  const fxERC20RootTunnel = await ethers.getContractAt('FxERC20RootTunnel', '0x2EEe18660B88248951285B3831D0F04149647d91')

  const setFxChildTunnel = await fxERC20RootTunnel.setFxChildTunnel(
    '0xaC6F975289Bc19ED65F02712FB75737E9cf097C2'
  );
  console.log(await setFxChildTunnel);
  // await setFxRootTunnel.wait();
  console.log("setFxChildTunnel set");

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
