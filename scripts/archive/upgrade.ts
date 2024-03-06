import { ethers, upgrades } from "hardhat"
import "dotenv/config"

async function main() {
  const testMode = true

  const newBonxNFTContractName = testMode ? "BONXTest" : "BONX"
  const newBondingContractName = testMode ? "BondingsCoreTest" : "BondingsCore"
  const proxyBonxNFTAddress = process.env.BONX_NFT!
  const proxyBondingAddress = process.env.BONDINGS_CORE!

  // For Bondings Core contract
  // console.log(`Upgrading ${newBondingContractName} contract for: 
  //   \x1b[32m${proxyBondingAddress}\x1b[0m`)
  // await upgradeContract(proxyBondingAddress, newBondingContractName)
  // console.log("Upgraded!")

  // For BONX NFT contract
  console.log(`Upgrading ${newBonxNFTContractName} contract for: 
    \x1b[32m${proxyBonxNFTAddress}\x1b[0m`)
  await upgradeContract(proxyBonxNFTAddress, newBonxNFTContractName)
  console.log("Upgraded!")
}

async function upgradeContract(proxyAddress: string, newContractName: string) {
  const newContractFactory = await ethers.getContractFactory(newContractName)
  const newContract = await upgrades.upgradeProxy(proxyAddress, newContractFactory)
  return newContract
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });