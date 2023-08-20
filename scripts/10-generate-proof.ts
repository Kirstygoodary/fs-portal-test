import { POSClient, use, setProofApi } from "@maticnetwork/maticjs";
import { ethers } from "ethers";
import { Web3ClientPlugin } from "@maticnetwork/maticjs-ethers";
import { Wallet, BigNumber } from "ethers";
import { FxPortalClient } from "@fxportal/maticjs-fxportal";


async function main() {

  //Setup
  use(Web3ClientPlugin);
  const parentProvider = new ethers.providers.JsonRpcProvider(
    "https://goerli.infura.io/v3/75aa7935112647bc8cc49d20beafa189"
  );
  const childProvider = new ethers.providers.JsonRpcProvider(
    "https://polygon-mumbai.infura.io/v3/7ff9e73bb4d04f9385724dc3936fa426"
  );
  const fromAddress = "0xB389a9aA1B44f527fE0401C73C7C8917ce9ADA07";

  const forParent = new Wallet(
    "424729f525ac2e1c5e37bde0bc8bf0e682a152375d50100a39b9815d3a5b2866",
    parentProvider
  );

  const forChild = new Wallet(
    "424729f525ac2e1c5e37bde0bc8bf0e682a152375d50100a39b9815d3a5b2866",
    childProvider
  );

  setProofApi("https://proof-generator.polygon.technology/");
  const fxPortalClient = new FxPortalClient();

  await fxPortalClient.init({
    network: "testnet", // 'testnet' or 'mainnet'
    version: "mumbai", // 'mumbai' or 'v1'
    parent: {
      provider: forParent,
      defaultConfig: {
        from: fromAddress,
      },
    },
    child: {
      provider: forChild,
      defaultConfig: {
        from: fromAddress,
      },
    },
  });

  //approve withdrawal on root chain
  // console.log("Approving....");
  
  const erc20Token = fxPortalClient.erc20(
    "0x2dd0849e27b78cb66E144A50105E785CFd815EAa",
    true
  );


  const amount = BigNumber.from(2).mul(BigNumber.from(10).pow(18));

  // console.log("here");
  // let result = await erc20Token.approve(amount.toString(), {gasPrice: 8000000000, gasLimit: 2100000});
  // console.log("not here");

  // let txHash = await result.getTransactionHash();
  // console.log("txHash", txHash);
  // let receipt = await result.getReceipt();
  // console.log("Approve receipt", receipt);

  // //deposit
  // console.log("Depositing....");
  // result = await erc20Token.deposit(
  //   amount.toString(),
  //   "0xB389a9aA1B44f527fE0401C73C7C8917ce9ADA07",
  //   {gasPrice: 8000000000, gasLimit: 2100000}
  // );

  // txHash = await result.getTransactionHash();
  // console.log("txHash", txHash);
  // receipt = await result.getReceipt();
  // console.log("Deposit receipt", receipt);



  console.log("mapped child address: ", await erc20Token.getMappedChildAddress())

  const childAddress = await erc20Token.getMappedChildAddress();

  const erc20TokenChild = fxPortalClient.erc20(
    childAddress,
    false
  );

  
  // const r = await erc20TokenChild.withdrawStart(amount.toString(), {gasPrice: 8000000000, gasLimit: 2100000});
  // const hash = await r.getTransactionHash();
  // const receipt2 = await r.getReceipt();
  // console.log("withdrawStart hash: ",hash)
  // console.log("receipt2", receipt2);

  console.log("isCheckpointed: ", await fxPortalClient.isCheckPointed('0xdb5332af32ead42372cf270c11e364186338e86f1c640cb5451c9043aa2cb769'));


  const result2 = await erc20Token.withdrawExitFaster('0xdb5332af32ead42372cf270c11e364186338e86f1c640cb5451c9043aa2cb769', {gasPrice: 8000000000, gasLimit: 2100000});
  const txHash2 = await result2.getTransactionHash();
  const receipt3 = await result2.getReceipt();
  console.log("withdrawExitFaster receipt: ",receipt3);

  // console.log("isExited: ", await erc20Token.isExited(hash));

};



main()
.then(() => process.exit(0))
.catch(error => {
console.error(error);
process.exit(1);
});
