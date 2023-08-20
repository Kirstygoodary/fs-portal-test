const matic = require("@maticnetwork/maticjs")
const { Web3ClientPlugin } = require("@maticnetwork/maticjs-web3")

async function main() {
// const matic = new Matic({
//   maticProvider: "https://rpc-mumbai.matic.today",
//   parentProvider: "https://goerli.infura.io/v3/75aa7935112647bc8cc49d20beafa189",
// });
// const exit_manager = matic.withdrawManager.exitManager;
// const BURN_HASH = '0x93540aa622cf56fe43106329419309d35c7977e8817895d995157192abfe5d5b';
// const SIG = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';
// const proof = await exit_manager.buildPayloadForExitHermoine(BURN_HASH, SIG);
// console.log("Burn proof:", proof);

/*
You may need to manually withdraw from the Polygon blockchain.
Once you've run the withdraw transaction on Polygon, you'll need to provide a burn proof on Ethereum.
Use the script below to generate the proof, then go to the WithdrawToWrapperRoot contract on Etherscan:
https://etherscan.io/address/0xb67a8438e15918de8f42aab84eb3950f2588a534
paste in the burn proof and enter '1' for the offset
*/

// You'll need the following packages


const { ExitUtil, Web3SideChainClient, RootChain, ABIManager } = matic
matic.use(Web3ClientPlugin)

const config = {
    network: 'mainnet',
    version: 'v1',
    parent: {
        provider: 'https://eth-goerli.g.alchemy.com/v2/Q7O028FyF9m6xw3n09Ucaw8Rlm9StUqn'
    },
    child: {
        provider: 'https://polygon-mumbai.g.alchemy.com/v2/mEoHNDidgHHPSp5vChGUIQ8UxQkW2LOO'
    },
}

// Don't change this
const TRANSFER_EVENT_SIG = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'

// Enter the Polygon tx hash of the withdrawal
const BURN_TX_HASH = '0x93540aa622cf56fe43106329419309d35c7977e8817895d995157192abfe5d5b'
// if there were multiple token transfers in the withdrawal, you can enter the index here
const INDEX_OF_TOKEN_TRANSFER = ''

const client = new Web3SideChainClient()
client.init(config).then(() => {
    const rootChain = new RootChain(client, '0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287')
    const exit = new ExitUtil(client, rootChain)
    return exit.buildPayloadForExit(BURN_TX_HASH, TRANSFER_EVENT_SIG, false, INDEX_OF_TOKEN_TRANSFER).then(console.log)
})
}


main()
.then(() => process.exit(0))
.catch(error => {
console.error(error);
process.exit(1);
});
