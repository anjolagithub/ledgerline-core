import { JsonRpcProvider, Wallet, Contract } from 'ethers';
import { proofGenerator } from '@gluwa/usc-sdk';
import * as dotenv from 'dotenv';
dotenv.config();

const MANAGER_ABI = [
  'function submitProof(uint8 action, uint64 blockHeight, bytes calldata encodedTransaction, tuple(bytes32 root, tuple(bytes32 hash, bool isLeft)[] siblings) merkleProof, tuple(bytes32 lowerEndpointDigest, bytes32[] roots) continuityProof) external',
];

interface ProofEvent { txHash: string; action: number; }

async function submitOne(
  sourceProvider: JsonRpcProvider,
  prover: any,
  manager: Contract,
  chainKey: number,
  event: ProofEvent
) {
  console.log(`\n--- Processing ${event.txHash} (action=${event.action}) ---`);

  const tx = await sourceProvider.getTransaction(event.txHash);
  if (!tx || tx.blockNumber === null) throw new Error(`Transaction not found or unmined: ${event.txHash}`);

  console.log(`  Waiting for Creditcoin to attest block ${tx.blockNumber}...`);
  await prover.waitUntilHeightAttested(chainKey, tx.blockNumber);
  console.log('  Block attested.');

  const result = await prover.generateProof(event.txHash);
  if (!result.success || !result.data) {
    throw new Error(`Proof generation failed: ${result.error}`);
  }
  const { headerNumber, txBytes, merkleProof, continuityProof } = result.data;
  console.log('  Proof fetched. Submitting to LedgerLineReadabilityManager...');

  const submitTx = await manager.submitProof(event.action, headerNumber, txBytes, merkleProof, continuityProof);
  const receipt = await submitTx.wait();
  console.log('  Submitted. Hub tx hash:', receipt!.hash);
}

async function main() {
  const chainKey = Number(process.env.SOURCE_CHAIN_KEY);

  const sourceProvider = new JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const creditcoinProvider = new JsonRpcProvider(process.env.CC3_RPC_URL);
  const wallet = new Wallet(process.env.PRIVATE_KEY!, creditcoinProvider);

  const prover = new proofGenerator.api.ProverAPIProofGenerator(chainKey, process.env.PROOF_BUILDER_URL!);
  const manager = new Contract(process.env.MANAGER_ADDRESS!, MANAGER_ABI, wallet);

  const input = JSON.parse(process.argv[2]);
  const events: ProofEvent[] = input.events;

  for (const event of events) {
    await submitOne(sourceProvider, prover, manager, chainKey, event);
  }

  console.log('\n=== All events processed. Check getCreditProfile() on the registry. ===');
}

main().catch((err) => { console.error(err); process.exit(1); });
