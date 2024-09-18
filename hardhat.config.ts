import { HardhatUserConfig } from 'hardhat/types'
import 'dotenv/config'
import '@nomicfoundation/hardhat-toolbox'
import { extendConfig } from 'hardhat/config';

extendConfig((config) => {
  if (!config.etherscan.customChains) {
    config.etherscan.customChains = [];
  }

  config.etherscan.customChains.push({
    network: "metabitMainnet",
    chainId: 4321,
    urls: {
      apiURL: "https://api.metabitglobal.io/api",
      browserURL: "https://www.metabitglobal.io",
    },
  });
});

const privateKey = process.env.NODE_ENV === 'production' ? process.env.MAINNET_PRIVATE_KEY : process.env.TESTNET_PRIVATE_KEY

const config: HardhatUserConfig = {
  solidity: '0.8.20',
  networks: {
    bscTestnet: {
      url: process.env.TESTNET_BSC_PROJECT_URL,
      accounts: [`0x${privateKey}`],
      gasPrice: 20000000000,
    },
    bscMainnet: {
      url: process.env.MAINNET_PROJECT_URL,
      chainId: 56,
      accounts: [`0x${privateKey}`],
      gasPrice: 20000000000,
    },
    metabitMainnet: {
      url: 'https://mainnet.rpc.metabitglobal.com/',
      chainId: 4321,
      accounts: [`0x${privateKey}`],
      gasPrice: 20000000000,
    },
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSCSCAN_API_KEY!,
      bscMainnet: process.env.BSCSCAN_API_KEY!,
      metabitMainnet: process.env.ETHERSCAN_API_KEY!,
    },
  },
}

export default config