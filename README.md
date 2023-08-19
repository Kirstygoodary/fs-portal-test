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

6.
