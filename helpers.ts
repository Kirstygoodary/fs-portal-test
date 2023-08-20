/// GNosis safe helpers

import { network } from "hardhat";
import { Contract, Wallet, ethers } from "ethers";
import { promises as fs } from "fs";
import SafeApiKit from "@safe-global/api-kit";
import {
  SafeTransactionDataPartial,
  SafeMultisigTransactionResponse,
} from "@safe-global/safe-core-sdk-types";
import Safe, { EthersAdapter } from "@safe-global/protocol-kit";
import { fxErc20 } from './fx-values';

/**
 * @notice This function creates an Ethers adapter.
 * @param execSigner The wallet that will be used to create the EthersAdapter.
 * @return The Ethers adapter instance.
 */
const createAdapter = (execSigner : any) => {
  const exec: EthersAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: execSigner,
  });
  return exec;
};

/**
 * @notice This function creates a Safe API kit instance for transaction service.
 * @param execSigner The wallet that will be used to create the EthersAdapter.
 * @return The Safe API kit instance.
 */
const createTxService = (execSigner: Wallet) => {
  const exec: EthersAdapter = createAdapter(execSigner);
  return new SafeApiKit({
    txServiceUrl: "https://safe-transaction-goerli.safe.global",
    ethAdapter: exec,
  });
};

/**
 * @notice This function creates a user safe using the provided address and signer.
 * @param execSigner The wallet that will be used to create the EthersAdapter.
 * @param safeAddress The address of the safe.
 * @return The Safe instance.
 */
const createUserSafe = async (execSigner: Wallet, safeAddress: string) => {
  const exec: EthersAdapter = createAdapter(execSigner);
  return await Safe.create({
    ethAdapter: exec,
    safeAddress: safeAddress,
  });
};

/**
 * @notice This function creates transaction data.
 * @param contractInstance Instance of the contract where the transaction will be executed.
 * @param methodName The method of the contract to be called.
 * @param params The parameters for the method.
 * @param userSdk The user's Safe SDK instance.
 * @return The transaction data.
 */
const createTxData = async (
  contractInstance: Contract,
  methodName: string,
  params: any[],
  userSdk: Safe
) => {
  const txdata: any = {
    to: contractInstance.address,
    data: contractInstance.interface.encodeFunctionData(methodName, params),
    value: "0",
  };

  const safeTransaction = await userSdk.createTransaction({
    safeTransactionData: txdata,
  });

  return safeTransaction;
};

/**
 * @notice This function proposes a transaction.
 * @param safeTransaction The safe transaction to be proposed.
 * @param userSdk The user's Safe SDK instance.
 * @param userWallet The user's wallet.
 * @return The signed transaction and transaction hash.
 */
const proposingTx = async (
  safeTransaction: any,
  userSdk: Safe,
  userWallet: Wallet
) => {
  const service = createTxService(userWallet);

  const safeTxHash = await userSdk.getTransactionHash(safeTransaction);
  const senderSignature = await userSdk.signTransactionHash(safeTxHash);

  await service.proposeTransaction({
    safeAddress: await userSdk.getAddress(),
    safeTransactionData: safeTransaction.data,
    safeTxHash,
    senderAddress: userWallet.address,
    senderSignature: senderSignature.data,
  });

  await service.confirmTransaction(safeTxHash, senderSignature.data);

  console.log(
    "Confirm transaction successful for transaction hash ",
    safeTxHash
  );

  console.log("Getting pending transactions");
  console.log("Getting pending tx....");
  const signedTx = await service.getTransaction(safeTxHash);
  return { signedTx: signedTx, safeTransactionHash: safeTxHash };
};

/**
 * @notice This function signs a proposed transaction.
 * @param userWallet The user's wallet.
 * @param userSdk The user's Safe SDK instance.
 * @param signedTx The signed transaction.
 * @param safeTxHash The transaction hash.
 * @return The safe transaction hash.
 */
const signProposedTx = async (
  userWallet: Wallet,
  userSdk: Safe,
  signedTx: any,
  safeTxHash: any
) => {
  // tx = await safeservice.getTransaction(safeTxHash)

  const service = createTxService(userWallet);

  const signerToo = await userSdk.signTransactionHash(signedTx.safeTxHash);
  await service.confirmTransaction(safeTxHash, signerToo.data);

  console.log(
    "Confirm transaction successful for transaction hash ",
    safeTxHash
  );

  return safeTxHash;
};

/**
 * @notice This function executes a signed transaction.
 * @param safeTxHash The transaction hash.
 * @param userWallet The user's wallet.
 * @param userSdk The user's Safe SDK instance.
 * @return The status of the executed transaction.
 */
const executeSignedTx = async (
  safeTxHash: any,
  userWallet: Wallet,
  userSdk: Safe
) => {
  const service = createTxService(userWallet);
  console.log("Getting pending transactions");
  const tx2 = await service.getTransaction(safeTxHash);

  console.log("Executing tx....");
  const isValidTx = await userSdk.isValidTransaction(tx2);
  console.log("Tx is valid: ", isValidTx);
  if (isValidTx) {
    const executeTxResponse = await userSdk.executeTransaction(tx2);
    const receipt =
      executeTxResponse.transactionResponse &&
      (await executeTxResponse.transactionResponse.wait());

    console.log("Transaction executed:");
    console.log(`https://goerli.etherscan.io/tx/${receipt.transactionHash}`);
  } else {
    console.log("Tx is invalid!");
  }

  return isValidTx;
};

/**
 * @notice This function is a module to execute a gnosis safe transaction.
 * @param contractInstance Instance of the contract where the transaction will be executed.
 * @param functionName The method of the contract to be called.
 * @param params The parameters for the method.
 * @param execSigner The wallet that will be used to create the EthersAdapter.
 * @param adminSigner The wallet of the admin.
 * @param safeAddress The address of the safe.
 * @return The status of the executed transaction.
 */
export const executeGnosisSafeTx = async (
  contractInstance: Contract,
  functionName: string,
  params: any[],
  execSigner: Wallet,
  adminSigner: Wallet,
  safeAddress: string
) => {
  //create exec adapter
  const exec = createAdapter(execSigner);

  //create service
  const service = createTxService(execSigner);

  //create safes
  const execSafe = await createUserSafe(execSigner, safeAddress);
  const adminSafe = await createUserSafe(adminSigner, safeAddress);

  const tx = await createTxData(
    contractInstance,
    functionName,
    params,
    execSafe
  );
  const { signedTx, safeTransactionHash } = await proposingTx(
    tx,
    execSafe,
    execSigner
  );

  const safeTxHash = await signProposedTx(
    adminSigner,
    adminSafe,
    signedTx,
    safeTransactionHash
  );

  const success = await executeSignedTx(safeTxHash, execSigner, execSafe);

  return success;
};

export const managerAbi = require("./artifacts/contracts/rewards/staking/StakingManager.sol/StakingManager.json");
export const factoryAbi = require("./artifacts/contracts/rewards/staking/StakingFactory.sol/StakingFactory.json");
export const rewardDropAbi = require("./artifacts/contracts/rewards/rewardDrop/RewardDropERC20.sol/RewardDropERC20.json");
export const governanceAbi = require("./artifacts/contracts/governance/GovernanceV1.sol/GovernanceV1.json");
export const stakingAbi = require("./artifacts/contracts/rewards/staking/Staking.sol/Staking.json");
export const tokenAbi = require("./artifacts/contracts/core/token/TOKEN.sol/TOKEN.json");
export const boostAbi = require("./artifacts/contracts/rewards/boost/Boostplays.sol/Boostplays.json");
export const accessAbi = require("./artifacts/contracts/core/security/Access.sol/Access.json");
export const pauserAbi = require("./artifacts/contracts/core/security/SystemPause.sol/SystemPause.json");
export const rewardPoolAbi = require("./artifacts/contracts/rewards/staking/RewardPool.sol/RewardPool.json");
export const weightCalculatorAbi = require("./artifacts/contracts/governance/WeightCalculator.sol/WeightCalculator.json");
export const fxErc20RootAbi = require("./artifacts/contracts/core/token/FxERC20RootTunnel.sol/FxERC20RootTunnel.json");
export const fxERC20ChildTunnelAbi = require("./artifacts/contracts/core/token/FxERC20ChildTunnel.sol/FxERC20ChildTunnel.json");
