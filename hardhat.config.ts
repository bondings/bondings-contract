import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.BASE_SCAN_API!,
      sepolia: process.env.ETHER_SCAN_API!,
    },
  },
  networks: {
    base: {
      url: process.env.BASE_RPC,
      accounts: [
        process.env.PRIVATE_KEY_ADMIN!,
      ]
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC,
      accounts: [
        process.env.PRIVATE_KEY_ADMIN!,
      ]
    },
  }
};

export default config;
