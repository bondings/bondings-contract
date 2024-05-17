import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  etherscan: {
    apiKey: {
      blast_sepolia: "blast_sepolia", // apiKey is not required, just set a placeholder
      base: process.env.BASE_SCAN_API!,
      sepolia: process.env.ETHER_SCAN_API!,
    },
    customChains: [
      {
        network: "blast_sepolia",
        chainId: 168587773,
        urls: {
          // 1. For Explorer: https://testnet.blastscan.io/
          // apiURL: "https://api.routescan.io/v2/network/testnet/evm/168587773/etherscan",
          // browserURL: "https://testnet.blastscan.io"
          // 2. For Explorer: https://sepolia.blastscan.io/ (Etherscan version)
          apiURL: "https://api-sepolia.blastscan.io/api",
          browserURL: "https://sepolia.blastscan.io/"
        }
      }
    ]
  },
  networks: {
    polygon: {
      url: process.env.POLYGON_RPC,
      accounts: [
        process.env.PRIVATE_KEY_ADMIN!,
      ]
      // gas: "auto",
      // gasPrice: 150000000000, // 150Gwei
    },
    blast_sepolia: {
      // url: process.env.BLAST_TEST_RPC,
      url: 'https://sepolia.blast.io',
      chainId: 168587773,
      accounts: [
        process.env.PRIVATE_KEY_ADMIN!,
      ]
    },
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

// r = json.load(open('artifacts/build-info/45b22d3bce577f28d713c4db698357da.json'))
// s = json.load(open('artifacts/build-info/compare.json'))
// r['output']['contracts']['contracts/mock/MockUSDB.sol']['MockUSDB']['metadata'] = s['metadata']
