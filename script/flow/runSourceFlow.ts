import { JsonRpcProvider, Wallet, Contract, parseEther } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

const REGISTRY_ABI = [
  'function registerLoan(address borrower, address withToken, uint256 loanAmount, uint256 expectedRepaymentAmount, uint256 deadlineTimestamp) external returns (uint256 loanId)',
];
const SETTLEMENT_ABI = [
  'function fundLoan(uint256 loanId, address borrower, address token, uint256 amount) external',
  'function repayLoan(uint256 loanId, address lender, address token, uint256 amount) external',
];
const TOKEN_ABI = [
  'function mint(address to, uint256 amount) external',
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function balanceOf(address account) external view returns (uint256)',
];

async function main() {
  const provider = new JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const wallet = new Wallet(process.env.PRIVATE_KEY!, provider);

  const registry = new Contract(process.env.SOURCE_REGISTRY_ADDRESS!, REGISTRY_ABI, wallet);
  const settlement = new Contract(process.env.SOURCE_SETTLEMENT_ADDRESS!, SETTLEMENT_ABI, wallet);
  const token = new Contract(process.env.DEMO_TOKEN_ADDRESS!, TOKEN_ABI, wallet);

  const borrower = wallet.address;
  const amount = parseEther('100');
  const expected = parseEther('110');
  const deadline = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
  const settlementAddr = process.env.SOURCE_SETTLEMENT_ADDRESS!;

  console.log('[0/5] Minting demo funds...');
  let tx = await token.mint(wallet.address, parseEther('1000'));
  await tx.wait();

  console.log('[1/5] Approving settlement contract (funding amount)...');
  tx = await token.approve(settlementAddr, amount);
  await tx.wait();

  console.log('[2/5] Registering loan...');
  tx = await registry.registerLoan(borrower, process.env.DEMO_TOKEN_ADDRESS!, amount, expected, deadline);
  const registerReceipt = await tx.wait();
  console.log('  Registered. Tx hash:', registerReceipt!.hash);

  console.log('[3/5] Funding loan (loanId=1)...');
  tx = await settlement.fundLoan(1, borrower, process.env.DEMO_TOKEN_ADDRESS!, amount);
  const fundReceipt = await tx.wait();
  console.log('  Funded. Tx hash:', fundReceipt!.hash);

  console.log('[4/5] Approving settlement contract (repayment amount)...');
  tx = await token.approve(settlementAddr, expected);
  await tx.wait();

  console.log('[5/5] Repaying loan (loanId=1)...');
  tx = await settlement.repayLoan(1, wallet.address, process.env.DEMO_TOKEN_ADDRESS!, expected);
  const repayReceipt = await tx.wait();
  console.log('  Repaid. Tx hash:', repayReceipt!.hash);

  console.log('\n=== Feed this into submitProofsToHub.ts ===');
  console.log(JSON.stringify({
    events: [
      { txHash: registerReceipt!.hash, action: 0 },
      { txHash: fundReceipt!.hash, action: 1 },
      { txHash: repayReceipt!.hash, action: 2 },
    ]
  }, null, 2));
}

main().catch((err) => { console.error(err); process.exit(1); });
