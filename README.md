# LedgerLine

**Proof-backed credit infrastructure for the real economy.**

LedgerLine is a cross-chain credit infrastructure protocol that turns **verified repayment activity into portable on-chain credit intelligence**.

A loan can originate and settle on a source chain such as Ethereum Sepolia while the resulting credit record is maintained on Creditcoin.

Instead of trusting a centralized oracle, spreadsheet, API response, or borrower declaration, LedgerLine uses **Creditcoin's Attestcoin Protocol** to cryptographically prove that the source-chain transaction actually occurred.

The verified event is then decoded, validated, and dispatched into LedgerLine's on-chain credit registry.

> **Proof before credit.**

---

## The Core Idea

LedgerLine separates **financial activity** from **credit intelligence**.

A source chain records what happened.

Attestcoin proves what happened.

LedgerLine records the resulting verified credit history.

```text
Source-chain financial event
        │
        ▼
Attestcoin attestation
        │
        ▼
Cryptographic transaction proof
        │
        ▼
LedgerLineReadabilityManager
        │
        ├── proof verification
        ├── transaction-status verification
        ├── authorized-emitter verification
        ├── event validation / decoding
        └── replay protection
        │
        ▼
LedgerLineRegistry
        │
        ▼
Verified borrower credit profile
```

The fundamental principle is simple:

> **Credit state should only change when the underlying financial event can be proven.**

---

# What LedgerLine Solves

Financial activity is increasingly fragmented across chains, lending protocols, payment systems, and financial platforms.

A borrower may successfully repay a loan on one network while attempting to access financing on another.

The destination lender needs reliable evidence that the repayment actually happened.

Traditional approaches can introduce trust assumptions through:

* Centralized credit databases
* Self-reported repayment history
* Spreadsheets
* API-based attestations
* Manually verified financial statements
* Centralized oracles
* Application-controlled databases

LedgerLine introduces a different model.

Instead of trusting a statement that:

> "This borrower repaid."

LedgerLine verifies evidence of the underlying source-chain transaction.

The verified event can then become part of the borrower's on-chain credit profile.

---

# How It Works

LedgerLine currently demonstrates a complete cross-chain loan lifecycle.

```text
┌──────────────────────────────────┐
│        SOURCE CHAIN              │
│        Ethereum Sepolia          │
│                                  │
│   Register Loan                  │
│          ↓                       │
│   Fund Loan                      │
│          ↓                       │
│   Repay Loan                     │
└────────────────┬─────────────────┘
                 │
                 │ Attestcoin proof
                 ▼
┌──────────────────────────────────┐
│        CREDITCOIN CC3             │
│                                  │
│   Block Prover                   │
│          ↓                       │
│   Receipt verification           │
│          ↓                       │
│   Event verification             │
│          ↓                       │
│   Authorized emitter check       │
│          ↓                       │
│   Replay protection              │
│          ↓                       │
│   Credit registry update         │
└──────────────────────────────────┘
```

## 1. Register

A lender registers a loan on the source chain.

The source registry records the loan terms and emits the canonical:

```text
LoanRegistered
```

event.

## 2. Fund

The lender funds the registered loan through the settlement contract.

The contract emits:

```text
LoanFunded
```

## 3. Repay

The borrower repays the loan.

The settlement contract emits:

```text
LoanRepaid
```

## 4. Prove

The resulting source-chain transaction is submitted through the Attestcoin verification flow.

LedgerLine's proof infrastructure generates the required transaction, Merkle, and continuity proofs.

## 5. Verify

The Creditcoin-side verification layer submits the proof to Creditcoin's native Block Prover.

LedgerLine then validates the proven receipt and expected event.

## 6. Update Credit

Only after the verification checks succeed is the verified financial event dispatched into `LedgerLineRegistry`.

The borrower's credit profile is then updated from verified on-chain activity.

---

# Why Attestcoin Matters

Attestcoin is not an optional feature in LedgerLine.

It is a core part of the protocol's trust model.

Without cross-chain verification, LedgerLine would need a trusted intermediary to tell Creditcoin that a repayment happened.

With Attestcoin, the system can instead establish a verifiable path:

```text
Source-chain transaction
        ↓
Attestcoin proof
        ↓
Creditcoin Block Prover
        ↓
Verified transaction receipt
        ↓
Verified LedgerLine event
        ↓
Credit profile update
```

This allows financial activity to remain on its originating chain while its verified credit consequences can be recognized on Creditcoin.

---

# Current Implementation

LedgerLine currently demonstrates:

* Ethereum Sepolia as the source chain
* Creditcoin CC3 Testnet as the credit-intelligence chain
* Attestcoin transaction-proof verification
* Native Creditcoin Block Prover precompile integration
* Verified source-chain event decoding
* Authorized source-contract validation
* Replay protection
* On-chain loan lifecycle tracking
* Repayment-based credit scoring
* Lender eligibility checks
* Invoice-financing policy consumption
* Live contract reads from the frontend

The source-chain contracts intentionally remain minimal.

The cross-chain verification boundary, credit registry, scoring logic, and downstream financing policy live on Creditcoin.

---

# Contracts

## Ethereum Sepolia

### `LedgerLineSourceRegistry`

Registers loan terms and emits the canonical `LoanRegistered` event.

### `LedgerLineSourceSettlement`

Handles source-chain loan funding and repayment transfers.

It emits:

* `LoanFunded`
* `LoanRepaid`

---

## Creditcoin CC3 Testnet

### `LedgerLineProofVerifier`

A thin integration layer around Creditcoin's native Block Prover precompile.

### `LedgerLineReadabilityManager`

The primary trust boundary of LedgerLine.

It:

1. Receives a proof
2. Verifies the proof
3. Verifies source-chain transaction success
4. Verifies the expected event
5. Verifies the authorized source emitter
6. Prevents replay
7. Decodes the proven receipt
8. Dispatches the verified event

### `LedgerLineRegistry`

The credit-intelligence layer.

It maintains:

* Loan lifecycle state
* Verified repayment totals
* Completed-loan count
* Borrower credit score
* Last update timestamp

### `LedgerLineFinancing`

A downstream consumer of the verified credit registry.

It applies a deterministic underwriting policy to verified borrower credit data and supports invoice-financing requests.

The financing layer is intentionally separated from the core verification and scoring engine.

---

# Deployed Testnet Contracts

| Contract                       | Network                | Address                                      |
| ------------------------------ | ---------------------- | -------------------------------------------- |
| `LedgerLineSourceRegistry`     | Ethereum Sepolia       | `0x1Af3D4ED1D2592DdAD9c13A3004006c9785eC6fF` |
| `LedgerLineSourceSettlement`   | Ethereum Sepolia       | `0xa00DeE06b5d8DD4889683d2d526a744C2Bd67297` |
| `LedgerLineRegistry`           | Creditcoin CC3 Testnet | `0xde8365dAF3CFdF952E2F946F19a4DcAcd57eFf0F` |
| `LedgerLineProofVerifier`      | Creditcoin CC3 Testnet | `0x859Cab6e9912ee39efD71f5957ecf0c61CB64494` |
| `LedgerLineReadabilityManager` | Creditcoin CC3 Testnet | `0xCC0B4686de40Ff5ae1e0B8d58Da9175e9090610D` |
| `LedgerLineFinancing`          | Creditcoin CC3 Testnet | See deployment output / broadcast artifact   |

### Networks

```text
Ethereum Sepolia
Chain ID: 11155111

Creditcoin CC3 Testnet
Chain ID: 102031
```

Creditcoin RPC:

```text
https://rpc.cc3-testnet.creditcoin.network
```

---

# Live Demonstration

The repository includes an end-to-end source-chain flow that demonstrates:

1. Minting demonstration token funds
2. Registering a loan
3. Funding the loan
4. Repaying the loan
5. Obtaining the resulting transaction hashes
6. Waiting for Creditcoin attestation
7. Generating Attestcoin proofs
8. Submitting proofs to Creditcoin
9. Verifying the source transactions
10. Updating the LedgerLine credit registry

The latest demonstrated source-chain transactions are:

### Loan Registration

```text
0xff0d3efc1eac63f918a185578222855f8918532640f43503962f6ee960bc0078
```

### Loan Funding

```text
0x8f56d40f0e9370fab7c0e30e8c1fb2a7079a3761d4b42c56a5d904187adb097e
```

### Loan Repayment

```text
0x45f46804615af83b450ab78f2485ef95e8dfc21702d7f506c1f7749564af00da
```

The corresponding source actions are:

```text
REGISTER = 0
FUND     = 1
REPAY    = 2
```

The proof-submission flow is implemented in:

```text
script/flow/submitProofsToHub.ts
```

---

# Credit Scoring

LedgerLine currently uses a deliberately simple and transparent scoring model.

### Initial Score

```text
500 / 1000
```

### Fully Repaid Loan

A borrower receives:

```text
+15 points
```

when a loan is fully repaid.

The maximum score is:

```text
1000
```

### Partial Repayment

Partial repayments increase verified repayment volume but do **not** independently increase the credit score.

This prevents repayment fragmentation from being used to artificially accumulate score increases by splitting one obligation into many smaller repayment events.

The current model therefore distinguishes between:

```text
Verified repayment activity
```

and:

```text
Completed credit obligations
```

See:

```text
docs/CREDIT_SCORING_MODEL.md
```

---

# Financing Layer

`LedgerLineFinancing` consumes verified metrics from `LedgerLineRegistry`.

The current deterministic policy is:

| Score      | Completed Loans | Advance Rate |
| ---------- | --------------: | -----------: |
| `< 600`    |             Any | Not eligible |
| `600–749`  |             ≥ 1 |          50% |
| `750–899`  |             ≥ 1 |          65% |
| `900–1000` |             ≥ 1 |          80% |

The resulting advance is additionally capped by the borrower's cumulative verified repayments.

This creates a downstream example of how **verified credit intelligence can be consumed by a financing application**.

The financing contract remains separate from the core proof-verification system.

---

# Security Model

LedgerLine is designed to **fail closed**.

The `LedgerLineReadabilityManager` does not simply accept a claim that a repayment occurred.

Before a source-chain event can affect credit state, the system requires the relevant verification conditions to pass.

```text
                 Source Transaction
                         │
                         ▼
                Cryptographic Proof
                         │
                         ▼
                 Block Prover
                         │
                         ▼
                Receipt Validation
                         │
                         ▼
                  Event Validation
                         │
                         ▼
              Authorized Emitter Check
                         │
                         ▼
                  Replay Protection
                         │
                         ▼
                Credit State Update
```

The manager validates:

* Configured source chain
* Cryptographic proof
* Successful source transaction
* Expected event signature
* Authorized source contract
* Previously unprocessed query
* Proven receipt data

If a required condition fails, the state-changing operation reverts.

See:

```text
docs/THREAT_MODEL.md
```

---

# Security Properties

The current architecture provides protection against several classes of incorrect state transitions:

### Invalid proofs

A failed proof cannot be dispatched into the credit registry.

### Failed source transactions

A transaction that did not successfully execute cannot become a valid credit event.

### Unauthorized emitters

A valid transaction from an unrelated contract cannot be interpreted as a LedgerLine financial event.

### Replay

The same verified query cannot be processed repeatedly to mutate credit state multiple times.

### Repayment fragmentation

Partial repayments do not independently increase the credit score, preventing simple score farming through fragmented repayment events under the current scoring model.

---

# Testing

LedgerLine uses Foundry for smart-contract testing.

Run:

```bash
forge build
```

Then:

```bash
forge test -vvv
```

The current repository test suite reports:

```text
34 tests passed
0 failed
0 skipped
```

The test suite currently covers:

* Source loan registration
* Lender authorization
* Invalid loan parameters
* Loan funding
* Loan repayment
* Invalid repayment conditions
* Proof failure
* Failed source transactions
* Unauthorized emitters
* Replay protection
* Verified loan registration
* Verified repayment processing
* Credit scoring
* Partial-repayment behavior
* Score bounds
* Duplicate loan protection
* Financing eligibility
* Advance-rate calculation
* Verified-repayment caps
* Invoice registration
* Financing requests
* Financing authorization
* Duplicate financing prevention
* Fuzz testing of score bounds

---

# Test Summary

Current suite:

```text
LedgerLineSourceRegistryTest       9 passed
LedgerLineSourceSettlementTest     4 passed
LedgerLineReadabilityManagerTest   6 passed
LedgerLineFinancingTest           10 passed
LedgerLineRegistryTest              5 passed
──────────────────────────────────────
TOTAL                              34 passed
```

---

# Frontend

The LedgerLine frontend consumes the deployed contracts through public RPC endpoints.

It provides interfaces for:

* Network status
* Wallet connection
* Credit-profile queries
* Verification lifecycle visualization
* Repayment/audit views
* Lender workspace
* Borrower workspace
* Invoice-financing demonstration
* Developer-facing contract information

The frontend is designed to distinguish between:

```text
LIVE ON-CHAIN DATA
```

and:

```text
DEMONSTRATION / PRODUCT DATA
```

Illustrative invoice records and underwriting examples are not represented as real customer data.

The canonical credit score and verified repayment metrics are read from the deployed LedgerLine contracts.

---

# Product Model

LedgerLine is designed around three primary participants.

## Borrowers

Borrowers build verifiable repayment history that can potentially become portable across lending environments.

## Lenders

Lenders can use verified repayment history as an additional input when evaluating borrowers.

## Credit Protocols

Credit protocols can consume verified credit information without requiring the original source-chain application to become a trusted reporting intermediary.

This positions LedgerLine as a **credit verification and reputation rail**, rather than simply a standalone scoring dashboard.

---

# Real-World Applications

The same verification architecture can support a range of credit and financing use cases:

* SME financing
* Merchant credit
* Invoice financing
* Trade finance
* Cross-border lending
* Supply-chain finance
* Embedded lending
* Alternative credit underwriting
* Cross-chain credit markets

The underlying model remains the same:

```text
Financial activity
       ↓
Source chain
       ↓
Cryptographic verification
       ↓
Creditcoin
       ↓
Verified credit intelligence
       ↓
Financing / underwriting
```

---

# Architecture Principles

## Verify, Don't Trust

Credit state should be derived from verifiable financial events rather than application assertions.

## Fail Closed

Invalid proofs, failed transactions, unauthorized emitters, and replayed queries must not update credit state.

## Minimal Source-Chain Logic

Source chains only contain the logic necessary to record the financial event.

## Separation of Concerns

Proof verification, credit registry logic, scoring, and financing policy are separated into distinct contracts.

## Deterministic Credit State

Verified events produce deterministic state transitions on Creditcoin.

## Transparent Scoring

The current scoring model is intentionally simple and auditable.

More sophisticated risk models can be added later without changing the fundamental proof-verification architecture.

---

# Current Limitations

LedgerLine is currently a **hackathon/testnet implementation**.

Known limitations include:

* Creditcoin CC3 Testnet deployment
* Ethereum Sepolia source chain
* Single configured source chain per `LedgerLineReadabilityManager` instance
* Simplified credit scoring
* No negative score adjustment for defaults yet
* No production KYB/KYC system
* Financing execution is not connected to a production capital provider
* Invoice data in the frontend remains demonstrative
* Production-grade relayer infrastructure is still required
* The current financing policy is deterministic and experimental rather than a production underwriting model

These limitations are explicitly documented rather than hidden assumptions.

---

# Roadmap

## Phase 1 — Cross-Chain Credit Proofs

**Current**

* Ethereum Sepolia source-chain integration
* Loan registration
* Loan funding
* Loan repayment
* Attestcoin proof generation
* Creditcoin Block Prover verification
* Verified event decoding
* Credit registry
* Repayment-based scoring
* Financing policy
* Testnet frontend

## Phase 2 — Multi-Chain Credit History

Extend LedgerLine to additional source chains supported by the Attestcoin verification infrastructure.

## Phase 3 — Lender Infrastructure

Build lender-facing infrastructure for:

* Borrower credit profiles
* Verified repayment history
* Proof provenance
* Eligibility rules
* Risk signals
* Financing workflows

## Phase 4 — Advanced Credit Intelligence

Introduce additional verified signals including:

* Repayment timeliness
* Loan size
* Loan duration
* Default history
* Portfolio behavior
* Historical performance

## Phase 5 — Production Credit Network

Build toward an interoperable credit network where lenders and financing protocols can consume verified repayment reputation across multiple financial environments.

---

# Documentation

The repository contains detailed documentation covering the protocol's architecture and operation.

* `docs/ARCHITECTURE.md` — Protocol architecture and design decisions
* `docs/ATTESTCOIN_INTEGRATION.md` — Proof-generation and verification flow
* `docs/CREDIT_SCORING_MODEL.md` — Scoring mechanics
* `docs/THREAT_MODEL.md` — Security assumptions and attack surfaces
* `docs/DEPLOYMENT.md` — Deployment and testnet operations
* `docs/TESTING.md` — Test strategy and coverage
* `docs/PRODUCT.md` — Product, users, workflows, and use cases
* `docs/WHITEPAPER.md` — Protocol thesis and long-term architecture
* `docs/DEMO.md` — Reproducible hackathon demonstration

---

# Repository Structure

```text
ledgerline-core/
│
├── src/
│   ├── LedgerLineRegistry.sol
│   ├── LedgerLineSourceRegistry.sol
│   ├── LedgerLineSourceSettlement.sol
│   ├── LedgerLineProofVerifier.sol
│   ├── LedgerLineReadabilityManager.sol
│   ├── LedgerLineFinancing.sol
│   │
│   ├── interfaces/
│   ├── types/
│   └── lib/
│       └── LedgerLineDecoder.sol
│
├── script/
│   ├── DeployHub.s.sol
│   ├── DeploySource.s.sol
│   ├── DeployFinancing.s.sol
│   ├── DeployDemoToken.s.sol
│   ├── RedeployManager.s.sol
│   └── flow/
│       ├── runSourceFlow.ts
│       └── submitProofsToHub.ts
│
├── test/
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── ATTESTCOIN_INTEGRATION.md
│   ├── CREDIT_SCORING_MODEL.md
│   ├── DEPLOYMENT.md
│   ├── TESTING.md
│   ├── THREAT_MODEL.md
│   ├── PRODUCT.md
│   ├── WHITEPAPER.md
│   
│
└── frontend/
```

---

# Deployment

Deployment instructions, environment configuration, Creditcoin-specific compiler requirements, contract deployment, and testnet operations are documented in:

```text
docs/DEPLOYMENT.md
```

---

# Originality

LedgerLine's contracts were written specifically for this project.

The architecture was informed by Creditcoin's public Attestcoin documentation and examples.

LedgerLine's credit registry, scoring engine, financing layer, source-chain loan lifecycle, verification boundary, and application architecture were developed as components of this project.

No claim is made that the project reproduces or copies proprietary implementation code.

---

# Hackathon Context

**BUIDL CTC 2026 Fall**

**Track:** RWA

**Core infrastructure:** Creditcoin + Attestcoin Protocol

LedgerLine uses Attestcoin as a fundamental part of its cross-chain verification architecture rather than as a peripheral integration.

---

# License

MIT
