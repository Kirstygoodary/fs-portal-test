import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import 'hardhat-contract-sizer';
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-tracer";
import 'hardhat-docgen';


require('dotenv').config();
const mumbaiAPIKey = process.env.MUMBAI_API_KEY;
const testnetDeployerPrivKey = process.env.TESTNET_DEPLOYER_PRIVATE_KEY;

const hardhatConfig: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
      hardhat: {
        chainId: 1337,
        gas: 999999999999,
        blockGasLimit: 999999999999,
        allowUnlimitedContractSize: false,
    },
      // localhost: {
      //   chainId: 8545,
      // },
      // goerli: {
      //   url: ALCHEMY_KEY,
      //   accounts: [`0x${TREASURY_KEY}`, `0x${ADMIN_KEY}`, `0x${DEPLOY_KEY}`],
      //   gas: 2100000,
      // },
      mumbai: {
        url: 'https://polygon-mumbai.g.alchemy.com/v2/cWETzsfTcZ2QDDWEWGtsi6l1GnTQgDhW',
        gas: 2100000,
        gasPrice: 8000000000,
        chainId: 80001,
        blockGasLimit: 999999999999,
        allowUnlimitedContractSize: false,
      }
    },
    solidity: {
      version: "0.8.9",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
      
    },
    paths: {
    },
    gasReporter: {
      currency: 'GBP',
      token: 'MATIC',
      enabled: false,
      noColors: false,
      showTimeSpent: true, 
      // outputFile: 'gas-report.txt',
      coinmarketcap: '39644bf2-2c65-480e-922f-60bcf713c1d1'
    },
    etherscan: {
      apiKey: {polygonMumbai:'E3FWWYM7WDMNG5NTQ3I7UUZWGS3MDIF8QJ'},
    },
    // docgen: {
    //   path: './docs',
    //   clear: true,
    //   runOnCompile: false,
    // }
    
  };

  

export default hardhatConfig;
