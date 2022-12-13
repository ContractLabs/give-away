// @ts-ignore
import { buildPoseidon, poseidonContract } from "circomlibjs";
import { BigNumber, BigNumberish, Contract, ContractFactory, Wallet, providers, utils } from "ethers";
import path from "path";
// @ts-ignore
import { groth16 } from "snarkjs";

import { Hasher, MerkleTree } from "./merkleTree";

const ETH_AMOUNT = utils.parseEther("1");
const HEIGHT = 20;

const node = new providers.JsonRpcProvider("https://rpc.ankr.com/avalanche_fuji");
const wallet = new Wallet("39a994f133c7a3ee7d7a8657878d7710575ea00b5b35b3be6473f88b41bf2c6e");
const account = wallet.connect(node);

const verifierContract = new Contract(
  "0x61fe7EF2f9288F3d62eEDfa544945d3e7D2A2c8f",
  [
    {
      inputs: [
        { internalType: "uint256[2]", name: "a", type: "uint256[2]" },
        { internalType: "uint256[2][2]", name: "b", type: "uint256[2][2]" },
        { internalType: "uint256[2]", name: "c", type: "uint256[2]" },
        { internalType: "uint256[5]", name: "input", type: "uint256[5]" },
      ],
      name: "verifyProof",
      outputs: [{ internalType: "bool", name: "r", type: "bool" }],
      stateMutability: "view",
      type: "function",
    },
  ],
  account,
);

function poseidonHash(poseidon: any, inputs: BigNumberish[]): string {
  const hash = poseidon(inputs.map((x) => BigNumber.from(x).toBigInt()));
  // Make the number within the field size
  const hashStr = poseidon.F.toString(hash);
  console.log("hashStr", hashStr);
  // Make it a valid hex string
  const hashHex = BigNumber.from(hashStr).toHexString();
  // pad zero to make it 32 bytes, so that the output can be taken as a bytes32 contract argument
  const bytes32 = utils.hexZeroPad(hashHex, 32);
  return bytes32;
}

class PoseidonHasher implements Hasher {
  poseidon: any;

  constructor(poseidon: any) {
    this.poseidon = poseidon;
  }

  hash(left: string, right: string) {
    return poseidonHash(this.poseidon, [left, right]);
  }
}

class Deposit {
  private constructor(public readonly nullifier: Uint8Array, public poseidon: any, public leafIndex?: number) {
    this.poseidon = poseidon;
  }
  static new(poseidon: any) {
    const nullifier = utils.randomBytes(3);
    return new this(nullifier, poseidon);
  }
  get commitment() {
    return poseidonHash(this.poseidon, [this.nullifier, 0]);
  }

  get nullifierHash() {
    if (!this.leafIndex && this.leafIndex !== 0) throw Error("leafIndex is unset yet");
    return poseidonHash(this.poseidon, [this.nullifier, this.leafIndex]);
  }
}

function getPoseidonFactory(nInputs: number) {
  const bytecode = poseidonContract.createCode(nInputs);
  const abiJson = poseidonContract.generateABI(nInputs);
  const abi = new utils.Interface(abiJson);
  return new ContractFactory(abi, bytecode);
}

interface Proof {
  a: [BigNumberish, BigNumberish];
  b: [[BigNumberish, BigNumberish], [BigNumberish, BigNumberish]];
  c: [BigNumberish, BigNumberish];
}

async function prove(witness: any): Promise<Proof> {
  let startingTick = Math.floor(new Date().getTime() / 1000);
  const wasmPath = path.join(__dirname, "../build/withdraw_js/withdraw.wasm");
  const zkeyPath = path.join(__dirname, "../build/circuit_final.zkey");

  const { proof } = await groth16.fullProve(witness, wasmPath, zkeyPath);
  const solProof: Proof = {
    a: [proof.pi_a[0], proof.pi_a[1]],
    b: [
      [proof.pi_b[0][1], proof.pi_b[0][0]],
      [proof.pi_b[1][1], proof.pi_b[1][0]],
    ],
    c: [proof.pi_c[0], proof.pi_c[1]],
  };
  console.log(`Finished in ${Math.floor(new Date().getTime() / 1000) - startingTick} seconds.`);
  return solProof;
}

async function test(): Promise<void> {
  const poseidon: any = await buildPoseidon();
  const tree = new MerkleTree(HEIGHT, "test", new PoseidonHasher(poseidon));
  const deposit = Deposit.new(poseidon);
  deposit.leafIndex = 1;

  await tree.insert(deposit.commitment);
  console.log();
  const { root, path_elements, path_index } = await tree.path(0);

  const witness = {
    // Public
    root,
    nullifierHash: "0x28BB28A2C7566E896A177DC7328D4298D197973BCAC177FB8291984A1CC43B7F",
    recipient: "0xf1684DaCa9FE469189A3202ae2dE25E80dcB90a1",
    token: "0xf1684DaCa9FE469189A3202ae2dE25E80dcB90a1",
    value: 1234,
    // Private
    nullifier: BigNumber.from(1).toBigInt(),
    pathElements: path_elements,
    pathIndices: path_index,
  };

  const solProof = await prove(witness);
  const r = await verifierContract.verifyProof(solProof.a, solProof.b, solProof.c, [
    root,
    deposit.commitment,
    "0xf1684DaCa9FE469189A3202ae2dE25E80dcB90a1",
    "0xf1684DaCa9FE469189A3202ae2dE25E80dcB90a1",
    1234,
  ]);
}

test();
