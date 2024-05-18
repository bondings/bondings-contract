import { ethers, upgrades } from "hardhat"
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers"
import { BondingsCore, BondingsToken } from "../typechain-types"
import { expect } from "chai"

const testnetMode = false
const bondingContractName = testnetMode ? 'BondingsCoreTest' : 'BondingsCore'
const bonxNFTContractName = testnetMode ? 'BONXTest' : 'BONX'

describe("test the functions related to assets management", function () {

  async function deployAssets() {
    const [admin, carol, david, treasury, operator] = await ethers.getSigners()

    // Deploy contracts
    const mockUSDC = await ethers.deployContract('MockUSDC')
    const bondingsCoreFactory = await ethers.getContractFactory(bondingContractName)
    const bondingsCore = (await upgrades.deployProxy(
      bondingsCoreFactory, [await mockUSDC.getAddress(), treasury.address]
    )) as unknown as BondingsCore
    const bondingsCoreAddress = await bondingsCore.getAddress()

    // Mint Tokens to Carol & David
    const amount = ethers.parseUnits('40000', 6)
    await mockUSDC.transfer(carol.address, amount)
    await mockUSDC.transfer(david.address, amount)
    await mockUSDC.connect(carol).approve(bondingsCoreAddress, amount)
    await mockUSDC.connect(david).approve(bondingsCoreAddress, amount)

    return { admin, carol, david, treasury, operator, bondingsCore, mockUSDC }
  }


  it("should deploy the contract correctly", async function () {
    await loadFixture(deployAssets)
  })


  it("should process correctly at stage 1/2/3", async function () {
    const { 
      admin, carol, david, operator, bondingsCore, mockUSDC 
    } = await loadFixture(deployAssets)

    const bondingsCoreAdmin = bondingsCore.connect(admin)
    const bondingsCoreCarol = bondingsCore.connect(carol)
    const bondingsCoreDavid = bondingsCore.connect(david)
    const bondingsCoreOperator = bondingsCore.connect(operator)

    // Set params
    await bondingsCoreAdmin.setHoldLimit(300)
    await bondingsCoreAdmin.setMintLimit(300)
    await bondingsCoreAdmin.setOperator(operator.address, true)
    await bondingsCoreAdmin.setBondingsTokenSupply(ethers.parseEther("1000000000"))

    // Carol buys 300 bondings
    const name = 'hello'
    await bondingsCoreCarol.launchBondings(name, 'hi')
    await bondingsCoreCarol.buyBondings(0, 150, 1000_000000)
    expect(await bondingsCore.getBondingsTotalShare(0)).to.equal(150)
    expect(await bondingsCore.bondingsStage(0)).to.equal(1)
    await bondingsCoreCarol.buyBondings(0, 150, 1000_000000)
    expect(await bondingsCore.getBondingsTotalShare(0)).to.equal(300)
    expect(await bondingsCore.bondingsStage(0)).to.equal(2)

    // David buys 2700 bondings and reach the max supply
    await bondingsCoreDavid.buyBondings(0, 2700, 10000_000000)
    expect(await bondingsCore.getBondingsTotalShare(0)).to.equal(3000)
    expect(await bondingsCore.bondingsStage(0)).to.equal(3)
    expect(await bondingsCore.userShare(0, carol.address)).to.equal(300)
    expect(await bondingsCore.userShare(0, david.address)).to.equal(2700)
    await expect(bondingsCoreCarol.buyBondings(0, 1, 100_000000))
      .to.be.revertedWith("Exceed max supply!")
    await expect(bondingsCoreCarol.sellBondings(0, 1, 0))
      .to.be.revertedWith("Bondings already in stage 3!")

    // Operator retrieves the assets
    await bondingsCoreOperator.retrieveAndDeploy(0)
    expect(await mockUSDC.balanceOf(await bondingsCore.getAddress())).to.equal(0)
    const b0TokenAddress = await bondingsCore.bondingsTokenAddress(0)
    const b0Token = (
      await ethers.getContractAt("BondingsToken", b0TokenAddress)
    ) as unknown as BondingsToken
    expect(await b0Token.balanceOf(await operator.getAddress()))
      .to.equal(ethers.parseEther("1000000000"))

    })

})