

import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");
import { Contract, Wallet } from "ethers";
import { tokenAbi, factoryAbi, managerAbi, pauserAbi, rewardPoolAbi, boostAbi, accessAbi, governanceAbi, weightCalculatorAbi, stakingAbi, fxERC20ChildTunnelAbi } from "../helpers";



async function main() {

  const abi = [
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "_fxChild",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "_tokenTemplate",
          "type": "address"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "bytes",
          "name": "message",
          "type": "bytes"
        }
      ],
      "name": "MessageSent",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "rootToken",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "childToken",
          "type": "address"
        }
      ],
      "name": "TokenMapped",
      "type": "event"
    },
    {
      "inputs": [],
      "name": "DEPOSIT",
      "outputs": [
        {
          "internalType": "bytes32",
          "name": "",
          "type": "bytes32"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "MAP_TOKEN",
      "outputs": [
        {
          "internalType": "bytes32",
          "name": "",
          "type": "bytes32"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "PREFIX_SYMBOL",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "SUFFIX_NAME",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "salt",
          "type": "bytes32"
        },
        {
          "internalType": "bytes32",
          "name": "bytecodeHash",
          "type": "bytes32"
        },
        {
          "internalType": "address",
          "name": "deployer",
          "type": "address"
        }
      ],
      "name": "computedCreate2Address",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "pure",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "fxChild",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "fxRootTunnel",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "stateId",
          "type": "uint256"
        },
        {
          "internalType": "address",
          "name": "rootMessageSender",
          "type": "address"
        },
        {
          "internalType": "bytes",
          "name": "data",
          "type": "bytes"
        }
      ],
      "name": "processMessageFromRoot",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "name": "rootToChildToken",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "_fxRootTunnel",
          "type": "address"
        }
      ],
      "name": "setFxRootTunnel",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "tokenTemplate",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "childToken",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "withdraw",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "childToken",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "receiver",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "withdrawTo",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]

  let provider = new ethers.providers.JsonRpcProvider(
    "https://polygon-mumbai.g.alchemy.com/v2/mEoHNDidgHHPSp5vChGUIQ8UxQkW2LOO"
  );
  let deployer: Wallet = new ethers.Wallet(`${process.env.DEPLOYER_2}`, provider);

  const fxERC20ChildTunnel = new Contract('0xaC6F975289Bc19ED65F02712FB75737E9cf097C2', abi, provider);

  const childToken = await fxERC20ChildTunnel.rootToChildToken('0x2dd0849e27b78cb66E144A50105E785CFd815EAa');

  console.log(childToken);

  // // here we are passing in the child token address and amount to withdraw
  const tx = await fxERC20ChildTunnel.connect(deployer).withdraw(childToken, ethers.utils.parseEther('2'));

  const receipt = await tx.wait(); 

  console.log(receipt);

  // balance should be 2 VEXT on Goerli
  }


	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
