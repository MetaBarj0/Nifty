import { beforeAll, test, describe } from "bun:test"

import { ethers } from "ethers"

let provider: ethers.JsonRpcProvider;
let alice: ethers.Wallet
let bob: ethers.Wallet

beforeAll(() => {
  setupProvider()
  setupWallets()
})

describe("Permit error cases", () => {
  test("Call to permit fails for invalid permit data", () => {
  })
})

function setupProvider() {
  const host = process.env["ANVIL_HOST"]
  const port = process.env["ANVIL_PORT"]

  provider = new ethers.JsonRpcProvider(`http://${host}:${port}`)
}

function setupWallets() {
  const alice_pk = process.env["TEST_PRIVATE_KEY_01"]!
  const bob_pk = process.env["TEST_PRIVATE_KEY_02"]!

  alice = new ethers.Wallet(alice_pk, provider)
  bob = new ethers.Wallet(bob_pk, provider)
}
