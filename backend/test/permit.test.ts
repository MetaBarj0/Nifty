import { beforeAll, test, describe, expect } from "bun:test"

import { ethers } from "ethers"

import { Nifty__factory, type Nifty } from "../typechain"

import latestRunJson from "../../contracts/broadcast/SetupPermit.s.sol/1/run-latest.json";

let provider: ethers.JsonRpcProvider;
let alice: ethers.Wallet
let bob: ethers.Wallet

let makeNiftyReadonly: () => Nifty
let makeNiftyWithSigner: (signer: ethers.Signer) => Nifty

type PermitData = {
  owner: ethers.AddressLike,
  spender: ethers.AddressLike,
  tokenId: ethers.BigNumberish,
  deadline: ethers.BigNumberish,
  nonce: ethers.BigNumberish,
  v: number,
  r: ethers.BytesLike,
  s: ethers.BytesLike
}

beforeAll(() => {
  setupProvider()
  setupWallets()
  setupContractsFactories()
})

describe("Permit error cases", () => {
  test.skip("An exemple to show how to sign ensuring it work at anvil's side", () => {
    const sk = new ethers.SigningKey(alice.privateKey)
    const h = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(["string"], ["encoded string"]))
    const s = sk.sign(ethers.getBytes(h));
    const sig = ethers.Signature.from(s);
    console.log(`pk: ${alice.privateKey}`)
    console.log(`sk: ${sk.privateKey}`)
    console.log(`addr: ${ethers.computeAddress(sk)}`)
    console.log(`h: ${h}`)
    console.log(`sig: ${JSON.stringify(sig)}`)
  })

  test("Permit call fails with expired deadline", async () => {
    const permitData: PermitData = {
      owner: ethers.ZeroAddress,
      spender: ethers.ZeroAddress,
      tokenId: 0,
      deadline: 0,
      nonce: 0,
      v: 0,
      r: ethers.encodeBytes32String(""),
      s: ethers.encodeBytes32String("")
    }

    await expectPermitCallRejectWith(permitData, "DeadlineExpired")
  })

  test("Permit call fails with invalid nonce", async () => {
    const permitData: PermitData = {
      owner: ethers.ZeroAddress,
      spender: ethers.ZeroAddress,
      tokenId: 0,
      deadline: getEpochAfterMinutes(10),
      nonce: 1,
      v: 0,
      r: ethers.encodeBytes32String(""),
      s: ethers.encodeBytes32String("")
    }

    await expectPermitCallRejectWith(permitData, "InvalidNonce")
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

function setupContractsFactories() {
  const niftyAddress =
    latestRunJson.transactions
      .filter((item) => item.contractName === "Nifty")
      .at(0)?.contractAddress!;

  makeNiftyReadonly = () => Nifty__factory.connect(niftyAddress, provider)
  makeNiftyWithSigner = (signer: ethers.Signer) => makeNiftyReadonly().connect(signer)
}

async function expectPermitCallRejectWith(permitData: PermitData, errorName: string) {
  try {
    await makeNiftyWithSigner(bob).permit(
      permitData.owner,
      permitData.spender,
      permitData.tokenId,
      permitData.deadline,
      permitData.nonce,
      permitData.v, permitData.r, permitData.s);
  } catch (error) {
    const e = error as { data: string }
    if (e.data) {
      const decodedError = makeNiftyReadonly().interface.parseError(e.data)

      expect(decodedError?.name).toBe(errorName)
    }
  }
}

function getEpochAfterMinutes(minutes: number) {
  return Math.floor(Date.now() / 1000) + minutes * 60
}
