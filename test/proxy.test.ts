// import { expect } from "chai"
// import { Contract, Signer, keccak256 } from "ethers"
// import { ethers, upgrades } from "hardhat"
// import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers"
// import { BONX, BondingsCore } from "../typechain-types"
// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers"

// describe("test the proxy deploy", function () {

//   it("should deploy the proxy contract correctly", async function () {
//     const [admin] = await ethers.getSigners()
//     const proxyAdminFactory = await ethers.getContractFactory('ProxyAdmin')
//     const proxyAdmin = await proxyAdminFactory.deploy(admin.address)

//     const bondingsCore = await ethers.deployContract('BondingsCore')

//     const transparentProxyFactory = await ethers.getContractFactory('TransparentUpgradeableProxy')
//     const transparentProxy = await transparentProxyFactory.deploy(
//       await bondingsCore.getAddress(), await proxyAdmin.getAddress(), '0x'
//     )

//     console.log("admin: ", admin.address)
//     console.log("proxy admin: ", await proxyAdmin.getAddress())

//     await proxyAdmin.upgradeAndCall(
//       await transparentProxy.getAddress(), await bondingsCore.getAddress(), '0x'
//     )
//   })
// })