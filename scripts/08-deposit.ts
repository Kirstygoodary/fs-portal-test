

import { ethers, upgrades } from "hardhat";
const hre = require("hardhat");
import { Contract, Wallet } from "ethers";
import { tokenAbi, factoryAbi, managerAbi, pauserAbi, rewardPoolAbi, boostAbi, accessAbi, governanceAbi, weightCalculatorAbi, stakingAbi, fxErc20RootAbi } from "../helpers";



async function main() {

  let provider = new ethers.providers.JsonRpcProvider(
    "https://eth-goerli.g.alchemy.com/v2/-sRSjnZS3Z27xu4YHwlqAjP86-pHE7uO"
  );
  let deployer: Wallet = new ethers.Wallet(`${process.env.DEPLOYER_2}`, provider);

  const abi = [
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "_checkpointManager",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "_fxRoot",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "_fxERC20Token",
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
          "indexed": true,
          "internalType": "address",
          "name": "rootToken",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "depositor",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "userAddress",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "FxDepositERC20",
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
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "userAddress",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "FxWithdrawERC20",
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
      "name": "TokenMappedERC20",
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
      "name": "SEND_MESSAGE_EVENT_SIG",
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
      "name": "checkpointManager",
      "outputs": [
        {
          "internalType": "contract ICheckpointManager",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "childTokenTemplateCodeHash",
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
      "inputs": [
        {
          "internalType": "address",
          "name": "rootToken",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "user",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "internalType": "bytes",
          "name": "data",
          "type": "bytes"
        }
      ],
      "name": "deposit",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "fxChildTunnel",
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
      "name": "fxRoot",
      "outputs": [
        {
          "internalType": "contract IFxStateSender",
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
          "name": "rootToken",
          "type": "address"
        }
      ],
      "name": "mapToken",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "",
          "type": "bytes32"
        }
      ],
      "name": "processedExits",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes",
          "name": "inputData",
          "type": "bytes"
        }
      ],
      "name": "receiveMessage",
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
      "name": "rootToChildTokens",
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
          "name": "_fxChildTunnel",
          "type": "address"
        }
      ],
      "name": "setFxChildTunnel",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]


  const fxErc20Root = new Contract('0x2EEe18660B88248951285B3831D0F04149647d91', abi, provider);

  const tx = await fxErc20Root.connect(deployer).deposit('0x2dd0849e27b78cb66E144A50105E785CFd815EAa', deployer.address, ethers.utils.parseEther('2'), 0x0);

  // depositing VEXT from Goerli to Mumbai via root tunnel on Goerli


  /**
   * params 
   *    address rootToken // VEXT token address 
        address user // receiver address
        uint256 amount // amount
        bytes memory data // 0x0
   */

  const receipt = await tx.wait(1);

  console.log(receipt)
  }


	main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
