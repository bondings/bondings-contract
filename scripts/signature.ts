import { ethers } from "ethers";
import "dotenv/config"

const SELECTOR_REGISTER = '0x8580974c'

function nowTime() {
  return parseInt((Date.now() / 1000).toString())
}

// async function signBaseRequest(selector: string, name: string, amount: string, user: string, time: number, signer: ethers.Wallet) {
//   const messageHexstring = ethers.solidityPacked(
//     ["bytes4", "string", "uint256", "address", "uint256"],
//     [selector, name, amount, user, time]
//   )
//   const messageBytes = ethers.getBytes(messageHexstring)
//   const signature = await signer.signMessage(messageBytes)
//   return { messageHexstring, signature, time }
// }

async function signRegister(name: string, user: string, signer: ethers.Wallet) {
  const time = nowTime()
  const messageHexstring = ethers.solidityPacked(
    ["bytes4", "string", "address", "uint256"],
    [SELECTOR_REGISTER, name, user, time]
  )
  const messageBytes = ethers.getBytes(messageHexstring)
  const signature = await signer.signMessage(messageBytes)
  return { messageHexstring, signature, time }
}

(async function () {
  const privateKey = process.env.PRIVATE_KEY_ADMIN!
  const wallet = new ethers.Wallet(privateKey)
  console.log('Signer address:', wallet.address)

  const amount = '7000000000'
  const user = '0xb54e978a34Af50228a3564662dB6005E9fB04f5a'

  const { messageHexstring, signature, time } = await signRegister('hello', user, wallet)

  console.log('Raw message:', messageHexstring)
  console.log('Signature:', signature)
  console.log('Timestamp: ', time)
})()

/**
 * 0x
 * 8580974c
 * 68656c6c6f
 * b54e978a34af50228a3564662db6005e9fb04f5a
 * 000000000000000000000000000000000000000000000000000000006598c785
 */