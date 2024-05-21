import { ethers } from "hardhat"
import "dotenv/config"
import { MetamaskConnector } from "@web3camp/hardhat-metamask-connector";

async function main() {
  const connector = new MetamaskConnector();
  const admin = await connector.getSigner();
  const adminAddress = await admin.getAddress();
  console.log("\x1b[0mSigner(Admin) Address:\x1b[32m", adminAddress, "\x1b[0m")

  const disperse = await ethers.deployContract('Disperse')
  console.log("\x1b[0mDisperse Contract deployed to:\x1b[32m", await disperse.getAddress())
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });