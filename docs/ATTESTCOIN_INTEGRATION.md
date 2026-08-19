# LedgerLine — Attestcoin Protocol Integration

## Why this is a core dependency, not a feature

LedgerLine's credit score cannot update without a successful Attestcoin
verification. There is no code path that lets a score change based on
self-reported or unverified data — every mutation to `CreditMetrics` traces
back through `LedgerLineReadabilityManager.submitProof()`.

## The real flow, as implemented

1. **Source-chain action.** A lender or borrower calls `registerLoan()`,
   `fundLoan()`, or `repayLoan()` on Ethereum Sepolia. Each emits a specific
   event (`LoanRegistered`, `LoanFunded`, `LoanRepaid`).
2. **Attestation wait.** The off-chain relayer (`script/flow/submitProofsToHub.ts`)
   calls `waitUntilHeightAttested()` from `@gluwa/usc-sdk`'s
   `ProverAPIProofGenerator`, polling until Creditcoin has attested the block
   containing the transaction.
3. **Proof generation.** `generateProof(txHash)` returns the transaction's
   ABI-encoded bytes, Merkle inclusion proof, and continuity proof.
4. **On-chain verification.** `LedgerLineProofVerifier` calls the real Block
   Prover precompile at `0x0000000000000000000000000000000000000FD2` via
   `verifyAndEmit()`, synchronously, in the same transaction.
5. **Real log decoding.** `LedgerLineDecoder` decodes the verified transaction's
   receipt (status, logs) from the ABI-encoded chunk format Attestcoin returns —
   not a pre-decoded or trusted parameter. It locates the matching event by
   signature *and* confirms the emitting contract is one of our two authorized
   source contracts.
6. **Dispatch.** Only after all of the above succeeds does
   `LedgerLineReadabilityManager` call into `LedgerLineRegistry` to update loan
   state and, on full repayment, the borrower's credit score.

## Verified on real infrastructure

- Precompile address, chain keys, and SDK usage were confirmed against
  Creditcoin's official documentation (`docs.creditcoin.org`) — not assumed.
- The full loop has run successfully end-to-end on live testnets: a real
  Sepolia repayment transaction, attested and proven, updated a real credit
  profile on Creditcoin CC3 Testnet.

## Deployed addresses

| Contract | Chain | Address |
|---|---|---|
| LedgerLineSourceRegistry | Sepolia | `0x1Af3D4ED1D2592DdAD9c13A3004006c9785eC6fF` |
| LedgerLineSourceSettlement | Sepolia | `0xa00DeE06b5d8DD4889683d2d526a744C2Bd67297` |
| LedgerLineRegistry | CC3 Testnet | `0xde8365dAF3CFdF952E2F946F19a4DcAcd57eFf0F` |
| LedgerLineProofVerifier | CC3 Testnet | `0x859Cab6e9912ee39efD71f5957ecf0c61CB64494` |
| LedgerLineReadabilityManager | CC3 Testnet | `0xCC0B4686de40Ff5ae1e0B8d58Da9175e9090610D` |
