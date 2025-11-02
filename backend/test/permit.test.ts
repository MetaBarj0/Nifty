import { beforeAll, test, describe } from "bun:test"
import { AbiCoder } from "ethers";

import { ethers } from "ethers"

import latestRunJson from "../../contracts/broadcast/PrepareForPermit.s.sol/1/run-latest.json";
import latestOutNiftyJson from "../../contracts/out/Nifty.sol/Nifty.json";

let provider: ethers.JsonRpcProvider;
let alice: ethers.Wallet
let bob: ethers.Wallet

let makeNiftyReadonly: () => ethers.Contract
let makeNiftyWithSigner: (signer: ethers.Signer) => ethers.Contract

beforeAll(() => {
  setupProvider()
  setupWallets()
  setupContractsFactories()
})

describe("Permit error cases", () => {
  test.skip("An exemple to show how to sign ensuring it work at anvil's side", () => {
    const sk = new ethers.SigningKey(alice.privateKey)
    const h = ethers.keccak256(AbiCoder.defaultAbiCoder().encode(["string"], ["encoded string"]))
    const s = sk.sign(ethers.getBytes(h));
    const sig = ethers.Signature.from(s);
    console.log(`pk: ${alice.privateKey}`)
    console.log(`sk: ${sk.privateKey}`)
    console.log(`addr: ${ethers.computeAddress(sk)}`)
    console.log(`h: ${h}`)
    console.log(`sig: ${JSON.stringify(sig)}`)
  })

  test("Permit call fails with invalid permit data", () => {
    const permitData = {
      owner: ethers.ZeroAddress,
      spender: ethers.ZeroAddress,
      tokenId: 0,
      deadline: 0,
      nonce: 0,
      v: 0,
      r: "",
      s: ""
    }

    makeNiftyWithSigner(bob).permit!(
      permitData.owner,
      permitData.spender,
      permitData.tokenId,
      permitData.deadline,
      permitData.nonce,
      permitData.v, permitData.r, permitData.s);
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
      .at(0)?.contractAddress;

  const niftyAbi = latestOutNiftyJson.abi;

  makeNiftyReadonly = () => new ethers.Contract(niftyAddress!, niftyAbi, provider);
  makeNiftyWithSigner = (signer: ethers.Signer) => makeNiftyReadonly().connect(signer) as ethers.Contract
}
