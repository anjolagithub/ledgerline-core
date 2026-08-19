# LedgerLine — Testing

## Running the suite

```bash
forge test -vv
```

## Coverage summary — 24 tests, all passing

- `LedgerLineRegistry.t.sol` (5 tests) — loan registration, duplicate
  protection, full vs. partial repayment scoring, and a 256-run fuzz test
  proving the score never exceeds 1000 regardless of repayment count.
- `LedgerLineSourceRegistry.t.sol` (9 tests) — loan registration, event
  emission, input validation, and the lender allowlist (approve/revoke,
  unapproved-caller rejection, owner-only gating).
- `LedgerLineSourceSettlement.t.sol` (4 tests) — fund/repay ERC20 transfers,
  zero-amount rejection, unapproved-transfer rejection.
- `LedgerLineReadabilityManager.t.sol` (6 tests) — proof verification success
  and failure, transaction-status rejection, unauthorized-emitter rejection,
  replay protection, and full dispatch against realistic synthetic
  transaction-receipt fixtures matching the real Attestcoin encoding format.

## What local tests can't cover

Local Foundry tests use a mock proof verifier — they prove the business logic
is correct given a valid proof, but can't test the real precompile or SDK
integration. That gap is closed by the live testnet run documented in
`ATTESTCOIN_INTEGRATION.md` — a real Sepolia transaction, verified through
the actual Block Prover precompile, updating a real credit score on CC3.

## A real bug the test suite caught before deployment

An early version of `LedgerLineReadabilityManager` called the proof
verifier's `verify()` function but never checked its boolean return value —
meaning a verifier that returned `false` without reverting would have been
silently treated as success. `test_RevertWhen_ProofFails` failed against this
version, surfacing the gap before it reached testnet.
