

import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");


async function main() {

	const FxERC20ChildTunnel = await hre.ethers.getContractFactory("FxERC20ChildTunnel");
  const fxERC20ChildTunnel = await FxERC20ChildTunnel.deploy('0xCf73231F28B7331BBe3124B907840A94851f9f11', '0x3b8Ff2D4C1f1407D698b7cbF2073916BA071A539');
  console.log("FxERC20ChildTunnel deployed to:", await fxERC20ChildTunnel.getAddress());
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
