# LedgerLine — Architecture

## Overview

LedgerLine is a cross-chain credit-scoring registry. A borrower's repayment on a
source chain (Ethereum Sepolia) is cryptographically proven via Creditcoin's
Attestcoin Protocol and used to update an on-chain credit profile on Creditcoin
CC3, with no centralized oracle or trusted intermediary.

## System diagram

[ Ethereum Sepolia ] [ Creditcoin CC3 Testnet ]

LedgerLineSourceRegistry LedgerLineProofVerifier

owner-gated lender allowlist - wraps the native Block Prover
registers loan terms precompile (0x...0FD2)
emits LoanRegistered

LedgerLineSourceSettlement LedgerLineReadabilityManager

fund/repay ERC20 transfers - verifies proofs synchronously
emits LoanFunded / LoanRepaid - decodes real transaction receipts
- replay protection
| - authorized-emitter checks
| (off-chain relayer: - dispatches to registry
| wait for attestation,
| fetch proof, submit)
v
LedgerLineRegistry
- loan lifecycle state machine
- CreditMetrics scoring engine
(original to LedgerLine)

## Design decisions

**Immutable, not upgradeable.** LedgerLine's core pitch is trust minimization —
no party should be able to silently rewrite scoring rules after deployment. We
chose immutable contracts with a `Pausable` safety valve over a proxy pattern,
trading upgrade convenience for a stronger trust story and less implementation
risk under time pressure.

**Minimal source-chain logic.** Per Attestcoin's documented best practice,
source-chain contracts (`LedgerLineSourceRegistry`, `LedgerLineSourceSettlement`)
do the minimum necessary — hold terms, move funds, emit clean events. All
business logic (scoring, lifecycle state) lives on Creditcoin.

**Fail-closed dispatch.** `LedgerLineReadabilityManager` requires proof
verification to succeed (return value explicitly checked), the transaction to
have succeeded on the source chain (status byte checked), the log to have been
emitted by a pre-configured authorized contract, and the query to not have been
processed before — all four checks independently enforced, any one failing
reverts the whole call.

**One hub instance, one source chain.** `configureSourceChain` binds this
deployment to exactly one `chainKey`. Multi-source-chain support is a
straightforward extension (index bindings by chainKey) but out of scope for
this submission.

## Repository layout

src/
interfaces/ IAttestcoinProofVerifier, ILedgerLineProofVerifier, ILedgerLineTarget
LedgerLineTypes.sol shared structs: LoanFlow, LoanTerms, LoanOrder, CreditMetrics
LedgerLineSourceRegistry.sol (Sepolia)
LedgerLineSourceSettlement.sol (Sepolia)
LedgerLineProofVerifier.sol (CC3 — precompile wrapper)
LedgerLineReadabilityManager.sol (CC3 — verify + decode + dispatch)
LedgerLineRegistry.sol (CC3 — scoring engine)
lib/LedgerLineDecoder.sol (CC3 — real receipt/log decoding)
test/ Foundry test suite, 24 tests including a 256-run fuzz test
script/ deploy scripts (Foundry) + off-chain relayer (TypeScript)

