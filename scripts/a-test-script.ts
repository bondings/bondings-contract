import { ethers } from "hardhat"
import { Disperse, MockUSDC } from "../typechain-types"
import "dotenv/config"

async function main() {
  const [admin] = await ethers.getSigners()
  const list = [
    '0x0a59649758aa4d66e25f08dd01271e891fe52199',
    '0x13e003a57432062e4eda204f687be80139ad622f',
    '0x20133ba3e00a40c6ab4e29f1ef6198bc1d6a13c5',
    '0x28c6c06298d514db089934071355e5743bf21d60',
    '0x2fff0f7809fec5f18d47a35f073e1373f6d37a78',
    '0x3388adbfd079d619a984569f456918a6d8be8223',
    '0x3dd9deb58dd3d0377b7446bfa086a346c6945b8d',
    '0x3eba2110108c649abc55fb12d3e3056c053dcdb6',
    '0x3ee18b2214aff97000d974cf647e7c347e8fa585',
    '0x40ec5b33f54e0e8a33a975908c5ba1c14e5bbbdf',
  ]

  const mockUSDC = (await ethers.getContractAt(
    'MockUSDC', process.env.SEPOLIA_USDC!, admin
  )) as unknown as MockUSDC
  const disperse = (await ethers.getContractAt(
    'Disperse', process.env.SEPOLIA_DISPERSE!, admin
  )) as unknown as Disperse

  // ===== Deploy Disperse Contract =====
  // const disperse = await ethers.deployContract('Disperse')
  // console.log("\x1b[0mDisperse Contract deployed to:\x1b[32m", await disperse.getAddress())

  // ===== Transfer token seperately =====
  // for (let i = 0; i < list.length; i++) {
  //   await mockUSDC.transfer(list[i], ethers.parseUnits('0.04', 6))
  // }

  // ===== Transfer token using Disperse Contract =====
  // await disperse.disperseToken(
  //   process.env.SEPOLIA_USDC!,
  //   list, list.map(() => ethers.parseUnits('0.04', 6))
  // )

  // ===== Transfer token using Disperse Contract (permissionless) =====
  await mockUSDC.approve(
    process.env.SEPOLIA_DISPERSE!, ethers.parseUnits('10', 6)
  )
  await disperse.disperseTokenPermissionless(
    process.env.SEPOLIA_USDC!,
    list, list.map(() => ethers.parseUnits('0.04', 6))
  )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });