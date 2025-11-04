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
  test("Permit call fails with expired deadline", async () => {
    const permitData: PermitData = {
      owner: alice,
      spender: bob,
      tokenId: 0,
      deadline: 0,
      nonce: 0,
      v: 0,
      r: ethers.encodeBytes32String(""),
      s: ethers.encodeBytes32String("")
    }

    await expectPermitCallRejectWith(bob, permitData, "DeadlineExpired")
  })

  test("Permit call fails with invalid nonce", async () => {
    const permitData: PermitData = {
      owner: alice,
      spender: bob,
      tokenId: 0,
      deadline: getEpochAfterMinutes(10),
      nonce: 1,
      v: 0,
      r: ethers.encodeBytes32String(""),
      s: ethers.encodeBytes32String("")
    }

    await expectPermitCallRejectWith(bob, permitData, "InvalidNonce")
  })

  test("Permit call fails for token that does not own to the owner", async () => {
    const validPermit =
      getPermit(alice,
        bob.address,
        10,
        getEpochAfterMinutes(10),
        0);

    await expectPermitCallRejectWith(bob, validPermit, "Unauthorized")
  })

  test("Permit call fails for invalid signer", async () => {
    let validPermit =
      getPermit(alice,
        bob.address,
        10,
        getEpochAfterMinutes(10),
        0);

    validPermit.owner = bob;

    await expectPermitCallRejectWith(bob, validPermit, "InvalidSigner")
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

async function expectPermitCallRejectWith(signer: ethers.Wallet, permitData: PermitData, errorName: string) {
  try {
    await makeNiftyWithSigner(signer).permit(
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

      return
    }
  }

  throw new Error(`Expected to fail with: "${errorName}" but did not fail`)
}

function getEpochAfterMinutes(minutes: number) {
  return Math.floor(Date.now() / 1000) + minutes * 60
}

function getPermit(owner: ethers.Wallet,
  spender: ethers.AddressLike,
  tokenId: ethers.BigNumberish,
  deadline: ethers.BigNumberish,
  nonce: ethers.BigNumberish): PermitData {
  const h =
    ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "address", "uint256", "uint256", "uint256"],
      [owner.address, spender, tokenId, deadline, 0]))

  const sk = new ethers.SigningKey(owner.privateKey)
  const s = sk.sign(ethers.getBytes(h));
  const sig = ethers.Signature.from(s);

  return {
    owner: owner.address,
    spender,
    tokenId,
    deadline,
    nonce,
    v: sig.v,
    r: sig.r,
    s: sig.s
  }
}
