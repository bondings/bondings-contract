import { expect } from "chai"
import { Contract, Signer, keccak256 } from "ethers"
import { ethers, upgrades } from "hardhat"
import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers"
import { BONX, BondingsCore } from "../typechain-types"
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers"

const testnetMode = false
const bondingContractName = testnetMode ? 'BondingsCoreTest' : 'BondingsCore'
const bonxNFTContractName = testnetMode ? 'BONXTest' : 'BONX'

const SELECTOR = {
  'deploy': '0x8580974c',
  'renewal': '0xeafd9330'
}

function connectbondingsCore(bondingsCore: Contract, signer: Signer) {
  return bondingsCore.connect(signer) as BondingsCore
}

function connectBonxNFT(bonxNFT: Contract, signer: Signer) {
  return bonxNFT.connect(signer) as BONX
}

function nowTime() {
  return parseInt((Date.now() / 1000).toString())
}

async function signDeployWithHardhat(name: string, user: string, signer: HardhatEthersSigner) {
  const time = nowTime()
  const messageHexstring = ethers.solidityPacked(
    ["bytes4", "string", "address", "uint256"],
    [SELECTOR.deploy, name, user, time]
  )
  const messageBytes = ethers.getBytes(messageHexstring)
  const signature = await signer.signMessage(messageBytes)
  return { messageHexstring, signature, time }
}

async function signRenewalWithHardhat(amount: string, user: string, signer: HardhatEthersSigner) {
  const time = nowTime()
  const messageHexstring = ethers.solidityPacked(
    ["bytes4", "uint256", "address", "uint256"],
    [SELECTOR.renewal, amount, user, time]
  )
  const messageBytes = ethers.getBytes(messageHexstring)
  const signature = await signer.signMessage(messageBytes)
  return { messageHexstring, signature, time }
}


describe("test the functions related to assets management", function () {

  async function deployAssets() {
    const [admin, carol, david, signer, treasury] = await ethers.getSigners()

    // Deploy contracts
    const mockUSDT = await ethers.deployContract('MockUSDT')
    const bonxNFTFactory = await ethers.getContractFactory(bonxNFTContractName)
    const bonxNFT = await upgrades.deployProxy(
      bonxNFTFactory, [signer.address, await mockUSDT.getAddress(), treasury.address]
    )

    const bondingsCoreFactory = await ethers.getContractFactory(bondingContractName)
    const bondingsCore = await upgrades.deployProxy(
      bondingsCoreFactory, [signer.address, await mockUSDT.getAddress(), treasury.address]
    )
    const bondingsCoreAddress = await bondingsCore.getAddress()

    // Mint Tokens to Carol & David
    const amount = ethers.parseUnits('40000', 6)
    await mockUSDT.transfer(carol.address, amount)
    await mockUSDT.transfer(david.address, amount)
    await mockUSDT.connect(carol).approve(bondingsCoreAddress, amount)
    await mockUSDT.connect(david).approve(bondingsCoreAddress, amount)

    return { admin, carol, david, signer, treasury, bondingsCore, mockUSDT, bonxNFT }
  }


  it("should deploy the contract correctly", async function () {
    await loadFixture(deployAssets)
  })


  it("should finish user journey", async function () {
    const {
      admin, carol, david, signer, treasury, bondingsCore, mockUSDT, bonxNFT
    } = await loadFixture(deployAssets)

    const bondingsCoreAdmin = connectbondingsCore(bondingsCore, admin)
    const bondingsCoreCarol = connectbondingsCore(bondingsCore, carol)
    const bondingsCoreDavid = connectbondingsCore(bondingsCore, david)
    const bonxNFTCarol = connectBonxNFT(bonxNFT, carol)
    const bonxNFTSigner = connectBonxNFT(bonxNFT, signer)

    // Carol register a new bonx "hello"
    const name = 'hello'
    await bondingsCoreCarol.deploy(
      name, nowTime(), (await signDeployWithHardhat(name, carol.address, signer)).signature
    )

    // Carol buy 10 bondings, David buy 5 bondings
    await bondingsCoreCarol.buyBondings(name, 9, 300)     // expected: 285 * 1.03 = 293(.55)
    await bondingsCoreDavid.buyBondings(name, 5, 800)   // expected: 730 * 1.03 = 751(.9)
    await bondingsCoreCarol.sellBondings(name, 7, 800)   // expected: 875 * 0.97 = 849(-.25)

    expect(await mockUSDT.balanceOf(carol.address)).to.equal
      ('40000000556')     // 40000_000000 - 293(.55) + 849(-.25) = 40000000556
    expect(await mockUSDT.balanceOf(david.address)).to.equal
      ('39999999249')     // 40000_000000 - 751   = 39999999249

    // Mint limit
    await expect(bondingsCoreCarol.buyBondings(name, 11, 50000))
      .to.be.revertedWith("Exceed mint limit in stage 1!")

    // Award the winner
    await bonxNFTSigner.safeMint(carol.address, name)
    expect(await bonxNFTSigner.ownerOf(1)).to.equal(carol.address)
    expect(await bonxNFTSigner.getNextTokenId()).to.equal(2)
    await bonxNFTCarol.transferFrom(carol.address, david.address, 1)
    expect(await bonxNFTSigner.ownerOf(1)).to.equal(david.address)
    await bonxNFTSigner.retrieveNFT(1)
    expect(await bonxNFTSigner.ownerOf(1)).to.equal(signer.address)

    // Fees collected
    expect(await mockUSDT.balanceOf(treasury.address)).to.equal
      ('55')      // 285 * .03 + 730 * .03 + 875 * .03 = 8(.55) + 21(.9) + 26(.25) = 55
  })


  it("should process correctly at stage 1/2/3", async function () {
    const {
      admin, carol, david, signer, treasury, bondingsCore, mockUSDT, bonxNFT
    } = await loadFixture(deployAssets)

    const bondingsCoreAdmin = connectbondingsCore(bondingsCore, admin)
    const bondingsCoreCarol = connectbondingsCore(bondingsCore, carol)
    const bondingsCoreDavid = connectbondingsCore(bondingsCore, david)

    // Carol register a new bonx "hello"
    const name = 'hello'
    await bondingsCoreCarol.deploy(
      name, nowTime(), (await signDeployWithHardhat(name, carol.address, signer)).signature
    )

    // Carol buy 50 bonding and sell 10
    for (let i = 0; i < 5; i++) {
      await bondingsCoreCarol.buyBondings(name, 10 - (i == 0 ? 1 : 0), 30000)
      // expected total: [293.55, 2250.55, 6267.55, 12344.55, 20481.55]
    }

    expect(await mockUSDT.balanceOf(carol.address)).to.equal
      ('39999958365')    // 40000_000000 - 41635(+2.5) = 39999958365 

    await expect(bondingsCoreCarol.buyBondings(name, 10, 400000)).to.be
      .revertedWith("Exceed hold limit in stage 1!")
    await bondingsCoreCarol.sellBondings(name, 10, 10000)      // expected total: 19885 * 0.97
    expect(await mockUSDT.balanceOf(carol.address)).to.equal
      ('39999977654')    // 39999958365 + 19289(-.55) = 39999977654

    // Change mint limit and hold limit
    await bondingsCoreAdmin.setHoldLimit(100)
    await bondingsCoreAdmin.setMintLimit(100)
    await bondingsCoreAdmin.setFairLaunchSupply(100)

    // Change max supply
    await bondingsCoreAdmin.setMaxSupply(610)
    await expect(bondingsCoreCarol.transferBondings(name, david.address, 20)).to.be
      .revertedWith("Transfer is only allowed in stage 3!")

    // David buy 70 bonding
    await bondingsCoreDavid.buyBondings(name, 70, 500000)      // expected total: 417095 * 1.03
    expect(await mockUSDT.balanceOf(david.address)).to.equal
      ('39999570393')    // 40000_000000 - 429607(.85) = 39999570393
    expect(await bondingsCoreDavid.getBondingsTotalShare(name)).to.equal('109')

    // Carol buy 500 bonding, and reach the max supply
    await bondingsCoreCarol.buyBondings(name, 500, 80_000000)  // expected total: 75036750 * 1.03
    expect(await mockUSDT.balanceOf(carol.address)).to.equal
      ('39922689802')    // 39999_977654 - 77_287852(+.5) = 39922689802
    expect(await bondingsCoreCarol.getBondingsTotalShare(name)).to.equal('609')
    expect(await bondingsCoreCarol.bondingsStage(name)).to.equal(3)
    expect(await bondingsCoreCarol.userShare(name, carol.address)).to.equal('539')

    // Carol transfer 100 bonding to David
    await bondingsCoreCarol.transferBondings(name, david.address, 100)
    expect(await bondingsCoreCarol.userShare(name, carol.address)).to.equal('439')
  })


  it("should renewal successfully", async function() {
    const {
      admin, carol, david, signer, treasury, bondingsCore, mockUSDT, bonxNFT
    } = await loadFixture(deployAssets)

    const bonxNFTCarol = connectBonxNFT(bonxNFT, carol)
    const bonxNFTSigner = connectBonxNFT(bonxNFT, signer)

    const name = "test233"

    await bonxNFTSigner.safeMint(carol.address, name)
    await mockUSDT.connect(carol).approve(await bonxNFT.getAddress(), 5000)
    await bonxNFTCarol.renewal(
      1, 5000, nowTime(), (await signRenewalWithHardhat("5000", carol.address, signer)).signature
    )
  })


  it("should deploy the contract correctly on Blast", async function () {
    const [admin, carol, david, signer, treasury] = await ethers.getSigners()

    const mockUSDT = await ethers.deployContract('MockUSDT')
    const bondingsCoreBlastFactory = await ethers.getContractFactory("BondingsCoreBlast")
    const bondingsCoreBlast = await upgrades.deployProxy(
      bondingsCoreBlastFactory, [signer.address, await mockUSDT.getAddress(), treasury.address]
    )
    const bondingsCorBlasteAddress = await bondingsCoreBlast.getAddress()
  })

})