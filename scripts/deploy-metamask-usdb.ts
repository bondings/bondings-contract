import { ethers, upgrades } from "hardhat"
import "dotenv/config"
import { BONX, BondingsCore, MockUSDB } from "../typechain-types"
import { MetamaskConnector } from "@web3camp/hardhat-metamask-connector";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

async function main() {
  const connector = new MetamaskConnector();
  const admin = await connector.getSigner();
  const adminAddress = await admin.getAddress();
  console.log("\x1b[0mSigner(Admin) Address:\x1b[32m", adminAddress, "\x1b[0m")

  const mUSDB = await deployMockUSDB(admin)
  console.log(
    "\x1b[0mBondings Mock USDB deployed to:\x1b[32m", 
    await mUSDB.getAddress(), "\x1b[0m"
  )
}

async function deployMockUSDB(admin: SignerWithAddress) {
  return (await ethers.deployContract("MockUSDB", { signer: admin })) as MockUSDB
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });