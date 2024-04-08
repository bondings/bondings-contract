import { ethers, upgrades } from "hardhat"
import "dotenv/config"
import { BondingsCore } from "../typechain-types"
import { MetamaskConnector } from "@web3camp/hardhat-metamask-connector";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

async function main() {
  const testMode = false

  const mUSDBAddress = process.env.SEPOLIA_USDC!
  const backendSignerAddress = process.env.BACKEND_SIGNER!
  const protocolFeeDestination = process.env.ADDRESS_FEE_DESTINATION!

  const connector = new MetamaskConnector();
  const admin = await connector.getSigner();
  const adminAddress = await admin.getAddress();
  console.log("\x1b[0mSigner(Admin) Address:\x1b[32m", adminAddress, "\x1b[0m")

  const bondingsCore = await deployBondingsCore(
    admin, backendSignerAddress, mUSDBAddress, protocolFeeDestination, testMode
  )
  console.log("\x1b[0mBondingsCore deployed to:\x1b[32m", await bondingsCore.getAddress())
}

async function deployBondingsCore(
  admin: SignerWithAddress,
  backendSignerAddress: string,
  uintTokenAddress: string,
  protocolFeeDestination: string,
  testMode: boolean
) {
  const bondingsCoreContractName = testMode ? "BondingsCoreTest" : "BondingsCore"
  const bondingsCoreFactory = await ethers.getContractFactory(
    bondingsCoreContractName, { signer: admin }
  )
  const bondingsCore = await upgrades.deployProxy(
    bondingsCoreFactory, [backendSignerAddress, uintTokenAddress, protocolFeeDestination],
  )
  return (bondingsCore as unknown as BondingsCore)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });