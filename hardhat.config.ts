import { HardhatUserConfig } from 'hardhat/types';
import * as dotenv from 'dotenv';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: '0.8.23',
  networks: {
    bscTestnet: {
      url: process.env.TESTNET_BSC_URL,
      chainId: 97,
      accounts: [process.env.TESTNET_PRIVATE_KEY as string],
      gasPrice: 20000000000,
    },
    bscMainnet: {
      url: process.env.MAINNET_BSC_URL,
      chainId: 56,
      accounts: [process.env.MAINNET_PRIVATE_KEY as string],
      gasPrice: 20000000000,
    },
  },
  sourcify: {
    enabled: true,
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSCSCAN_API_KEY!,
      bscMainnet: process.env.BSCSCAN_API_KEY!,
      bsc: process.env.BSCSCAN_API_KEY!,
    },
  },
};

export default config;
