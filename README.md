# fs-portal-test

## Deployment

1. Deploy the VEXT token on Goerli
   `npx hardhat run scripts/00-deploy-token.ts --network goerli`

2. Deploy FxERC20 contract on the Goerli network
   `npx hardhat run scripts/01-deploy-fxErc20-goerli.ts --network goerli`

3. Deploy FxERC20 contract on the Mumbai network
   `npx hardhat run scripts/02-deploy-fxErc20-mumbai.ts --network mumbai`

4. Deploy FxERC20RootTunnel contract on the Goerli network
   `npx hardhat run scripts/scripts/scripts/03-deploy-root-tunnel.ts --network goerli`

5. Deploy FxERC20ChildTunner contract on the Mumbai network
   Set the FXERC20RootTunnel address
   `npx hardhat run scripts/04-deploy-child-tunnel.ts --network mumbai`

6. Mint tokens to EOA on Goerli
   `npx hardhat run scripts/06-mint-tokens.ts --network goerli`

7. Approve FxERC20RootTunnel to transfer tokens
   `npx hardhat run scripts/07-approve-tunnel.ts --network goerli`

8. Deposit via FxERC20RootTunnel on Goerli
   `npx hardhat run scripts/08-deposit.ts --network goerli`

9. Withdraw back to Goerli from Mumbai
   `npx hardhat run scripts/09-withdraw.ts  --network mumbai`

10. Generate proof to mint back to Goerli
    `ts-node scripts/10-generate-proof.ts`
