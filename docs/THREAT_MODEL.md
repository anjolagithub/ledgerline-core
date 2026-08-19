# LedgerLine — Threat Model

| Risk | Mitigation | Status |
|---|---|---|
| Self-dealing lender registers and repays a fake loan to themselves | Owner-gated lender allowlist (`approvedLenders`) enforced on the source-chain registry itself, not just the hub | Implemented, tested |
| Replay of a valid proof to inflate score multiple times | `processedQueries` mapping keyed by chain + block height + full transaction bytes | Implemented, tested |
| Spoofed source contract — a log that matches an event signature but wasn't emitted by our real contracts | Decoder confirms both event signature *and* emitting contract address before dispatch | Implemented, tested |
| A failing source-chain transaction still gets processed | Receipt status byte explicitly checked (`status != 1` reverts) | Implemented, tested |
| Proof verifier returns `false` without reverting, silently accepted | Manager explicitly checks the boolean return value rather than trusting the callee | Implemented, tested (caught by our own test suite before deployment) |
| Score gamed via many tiny repayments | Score only increments on full repayment | Implemented, tested |
| Wrong event signature accepted or a real one silently rejected | Caught in practice during our own testnet run — an incorrectly computed event hash caused a legitimate transaction to be rejected; fixed and redeployed | Real incident, resolved |
| Borrower identity linked to sensitive real-world financial data on an immutable public ledger | Documented Phase 2 direction: hashed metadata or ZK proofs for identity | Documented, not built |
| Gas cost of proof submission at scale | Attestcoin SDK supports batch proofs (`generateBatchProof`, up to 10 tx per batch) | Documented, not implemented |
| Centralized control via upgradeable contracts | Deliberately not upgradeable — a `Pausable` circuit breaker exists instead, trading upgrade convenience for trust minimization | Design decision |
