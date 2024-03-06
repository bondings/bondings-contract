import { ethers, upgrades } from "hardhat"
import "dotenv/config"
import { MetamaskConnector } from "@web3camp/hardhat-metamask-connector"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

async function main() {
  const testMode = false

  const newBondingContractName = testMode ? "BondingsCoreTest" : "BondingsCore"
  const proxyBondingAddress = process.env.BLAST_BONDINGS_CORE!

  const connector = new MetamaskConnector();
  const admin = await connector.getSigner();

  // For Bondings Core contract
  console.log(`\x1b[0mUpgrading ${newBondingContractName} contract for: ` + 
              `\x1b[32m${proxyBondingAddress}\x1b[0m`)
  await upgradeContract(
    admin, proxyBondingAddress, newBondingContractName
  )
  console.log("Upgraded!")

}

async function upgradeContract(
  admin: SignerWithAddress,
  proxyAddress: string, 
  newContractName: string
) {
  const newContractFactory = await ethers.getContractFactory(newContractName, { signer: admin })
  const newContract = await upgrades.upgradeProxy(proxyAddress, newContractFactory)
  return newContract
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });