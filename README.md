<img width="1300" height="795" alt="03-b2b-architecture" src="https://github.com/user-attachments/assets/24435dd9-32ec-4c5d-88d3-4b3738b0220c" /># LedgerLine

## B2B Credit Verification Infrastructure

### Proof Before Credit.

LedgerLine verifies financial activity across chains and turns **cryptographically proven repayment events into portable credit intelligence** for lenders, fintechs, RWA platforms, and credit protocols.

**Ethereum Sepolia → Attestcoin → Creditcoin CC3**

> **Proof before credit.**

---

## Status

* ✓ Source-chain contracts deployed
* ✓ Cross-chain proof verification implemented
* ✓ Credit profile updates implemented
* ✓ 34 tests passing
* ✓ Working frontend demo
* ✓ Attestcoin / USC integration implemented
* ✓ Ethereum Sepolia → Creditcoin CC3 flow demonstrated

**Current environment:** Creditcoin CC3 Testnet

---

## What Is LedgerLine?

Financial activity is increasingly distributed across different blockchains, lending protocols, payment systems, and financial platforms.

Credit history is not.

A borrower may repay a loan on one network and later seek financing somewhere else. The repayment exists, but the next lender needs trustworthy evidence that it actually happened.

LedgerLine provides that verification layer.

A source chain records the financial activity. Attestcoin provides cryptographic evidence of that activity. LedgerLine validates the proven event and converts it into reusable credit intelligence on Creditcoin.

```text
Source-chain financial event
            │
            ▼
     Attestcoin / USC
            │
            ▼
  Cryptographic proof
            │
            ▼
 Creditcoin Block Prover
            │
            ▼
LedgerLine verification boundary
            │
            ├── transaction success
            ├── expected event
            ├── authorized emitter
            └── replay protection
            │
            ▼
   LedgerLine Registry
            │
            ▼
   Verified credit profile
            │
            ▼
 Lender / Financing Decision
```

The fundamental principle is:

> **Credit state should only change when the underlying financial event can be proven.**

---

# The Problem

A lender can be told:

> "This borrower repaid a previous loan."

But where did that information come from?

It could come from:

* a centralized database
* an API
* a spreadsheet
* an application backend
* a borrower declaration
* a centralized oracle

LedgerLine changes the trust model.

Instead of trusting the party reporting the repayment, LedgerLine verifies evidence of the underlying source-chain transaction.

```text
"Borrower repaid"
       ↓
   Evidence
       ↓
Cryptographic verification
       ↓
Verified financial event
       ↓
Credit intelligence
```

---

# What LedgerLine Is — and Is Not

### LedgerLine is

* B2B credit verification infrastructure
* Cross-chain financial verification infrastructure
* Provenance-backed credit intelligence
* Infrastructure for lenders and financing platforms
* A verification layer between financial activity and underwriting

### LedgerLine is not

* A consumer credit-score application
* A lending marketplace
* A centralized credit bureau
* A centralized oracle
* A single-chain credit system
* A Web3-only reputation application

### Web3 is the infrastructure. Finance is the market.

The blockchain provides the verification and settlement primitives.

The long-term customers are expected to be:

* lenders
* banks
* fintechs
* RWA financing platforms
* credit protocols
* trade-finance providers
* financial infrastructure companies

---

# Architecture

## Source Chain

LedgerLine currently uses **Ethereum Sepolia** as its source-chain demonstration environment.

The source contracts handle the financial lifecycle:

```text
Register → Fund → Repay
```

### `LedgerLineSourceRegistry`

Registers loan terms and emits:

```text
LoanRegistered
```

### `LedgerLineSourceSettlement`

Handles:

* loan funding
* loan repayment

and emits:

```text
LoanFunded
LoanRepaid
```

---

## Cross-Chain Verification

After the source-chain transaction is finalized and attested, LedgerLine generates the required proof material through the Attestcoin / USC flow.

The proof path includes:

* transaction proof
* Merkle proof
* continuity proof

These are submitted to Creditcoin's native verification infrastructure.

---

## Creditcoin

### `LedgerLineProofVerifier`

A thin integration layer around Creditcoin's native Block Prover precompile.

### `LedgerLineReadabilityManager`

The primary trust boundary of LedgerLine.

It:

1. Receives the proof
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

* loan lifecycle state
* verified repayment totals
* completed-loan count
* borrower credit score
* last update timestamp

### `LedgerLineFinancing`

A downstream consumer of the verified credit registry.

It applies a deterministic financing policy to verified borrower credit data and supports the current invoice-financing demonstration.

The financing layer is intentionally separated from the core verification and scoring engine.

---

# Architecture Diagram
<img width="1312" height="1199" alt="image" src="https://github.com/user-attachments/assets/4d676f22-c400-43db-9b6e-82a8e8e681b9" />


<img width="1300" height="795" alt="03-b2b-architecture" src="https://github.com/user-attachments/assets/f20323d7-1c9c-4361-9802-157aa681b111" />

### Recommended diagram

```text
                    LEDGERLINE
          B2B CREDIT VERIFICATION INFRASTRUCTURE


┌──────────────────────────────────────┐
│          SOURCE CHAIN               │
│          Ethereum Sepolia           │
│                                      │
│     LedgerLine Source Contracts      │
│                                      │
│       Register → Fund → Repay        │
└──────────────────┬───────────────────┘
                   │
                   │ Financial Event
                   ▼
┌──────────────────────────────────────┐
│          ATTESTCOIN / USC            │
│                                      │
│ Source Block Attestation             │
│ Transaction Proof                    │
│ Merkle Proof                         │
│ Continuity Proof                     │
└──────────────────┬───────────────────┘
                   │
                   │ Cryptographic Evidence
                   ▼
┌──────────────────────────────────────┐
│          CREDITCOIN CC3              │
│                                      │
│ Native Block Prover / Precompile     │
│              │                       │
│              ▼                       │
│   LedgerLineReadabilityManager       │
│                                      │
│ Proof → Receipt → Event → Emitter    │
│              → Replay Protection     │
└──────────────────┬───────────────────┘
                   │
                   │ Verified Event
                   ▼
┌──────────────────────────────────────┐
│         LEDGERLINE REGISTRY           │
│                                      │
│ Verified Loans                       │
│ Verified Repayments                  │
│ Credit Profile                       │
│ Credit Intelligence                  │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│       FINANCIAL CONSUMERS             │
│                                      │
│ Lenders / Fintechs / RWA / Credit    │
│ Protocols / Financing Platforms      │
└──────────────────────────────────────┘
```

---

# How It Works

LedgerLine currently demonstrates a complete cross-chain loan lifecycle.

## 1. Register

A lender registers a loan on Ethereum Sepolia.

The source registry emits:

```text
LoanRegistered
```

## 2. Fund

The lender funds the registered loan.

The settlement contract emits:

```text
LoanFunded
```

## 3. Repay

The borrower repays the loan.

The settlement contract emits:

```text
LoanRepaid
```

## 4. Attest and Prove

The resulting source-chain transaction enters the Attestcoin verification flow.

LedgerLine generates the required transaction, Merkle, and continuity proofs.

## 5. Verify

The proof is submitted to Creditcoin's native Block Prover.

LedgerLine then validates the proven receipt and application event.

## 6. Update Credit

Only after the verification checks succeed is the event dispatched into `LedgerLineRegistry`.

The verified repayment can then update the borrower's credit profile.

---

# Why Attestcoin Matters

Attestcoin is a core component of LedgerLine's trust model.

Without cross-chain verification, LedgerLine would need a trusted intermediary to tell Creditcoin:

> "A repayment happened."

With Attestcoin:

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

# Deployed Testnet Contracts

## Ethereum Sepolia

| Contract                     | Address                                      |
| ---------------------------- | -------------------------------------------- |
| `LedgerLineSourceRegistry`   | `0x1Af3D4ED1D2592DdAD9c13A3004006c9785eC6fF` |
| `LedgerLineSourceSettlement` | `0xa00DeE06b5d8DD4889683d2d526a744C2Bd67297` |

## Creditcoin CC3 Testnet

| Contract                       | Address                                      |
| ------------------------------ | -------------------------------------------- |
| `LedgerLineRegistry`           | `0xde8365dAF3CFdF952E2F946F19a4DcAcd57eFf0F` |
| `LedgerLineProofVerifier`      | `0x859Cab6e9912ee39efD71f5957ecf0c61CB64494` |
| `LedgerLineReadabilityManager` | `0xCC0B4686de40Ff5ae1e0B8d58Da9175e9090610D` |
| `LedgerLineFinancing`          | `0x22fA5c1C36Cc1F7557B932dE7aCDa354ee4F6F52` |

### Networks

```text
Ethereum Sepolia
Chain ID: 11155111

Creditcoin CC3 Testnet
Chain ID: 102031
```

### Creditcoin Block Prover

```text
0x0000000000000000000000000000000000000FD2
```

---

# Live Transaction Evidence

The source-chain demonstration has already produced the following transactions:

| Action                      | Network          | Transaction                                                          |
| --------------------------- | ---------------- | -------------------------------------------------------------------- |
| Loan registered             | Ethereum Sepolia | `0xff0d3efc1eac63f918a185578222855f8918532640f43503962f6ee960bc0078` |
| Loan funded                 | Ethereum Sepolia | `0x8f56d40f0e9370fab7c0e30e8c1fb2a7079a3761d4b42c56a5d904187adb097e` |
| Loan repaid                 | Ethereum Sepolia | `0x45f46804615af83b450ab78f2485ef95e8dfc21702d7f506c1f7749564af00da` |
| Cross-chain proof submitted | Creditcoin CC3   | `0x3abe339877ae974625a0571e9f5ab08a73d881be335850eae3ac32c892d8b2f6`                                   |
| Credit profile updated      | Creditcoin CC3   | `0x3abe339877ae974625a0571e9f5ab08a73d881be335850eae3ac32c892d8b2f6`                               |

The final submission should replace the two placeholders with the actual Creditcoin transaction hashes.

---

# Frontend

The LedgerLine frontend consumes the deployed contracts through public RPC endpoints.

It provides:

* Network status
* Wallet connection
* Credit-profile queries
* Verification lifecycle visualization
* Repayment/audit views
* Lender workspace
* Borrower workspace
* Invoice-financing demonstration
* Developer-facing contract information

The frontend distinguishes between:

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

# Frontend Screenshots

## 1. Credit Profile

<img width="1919" height="975" alt="image" src="https://github.com/user-attachments/assets/d6043882-59d5-4891-aed0-a258806c3030" />


Recommended view:

* Credit score
* Completed loans
* Verified repayment volume
* Verification status
* Source chain
* Creditcoin network

---

## 2. Repayment Verification

<img width="1913" height="1033" alt="image" src="https://github.com/user-attachments/assets/704eb012-f564-48d1-a8ac-b0d9ab6b4e99" />


Recommended view:

* Repayment transaction
* Source chain
* Attestation status
* Proof status
* Creditcoin verification
* Event information
* Credit-state update

---

## 3. Lender / Underwriting View

<img width="1913" height="826" alt="image" src="https://github.com/user-attachments/assets/afcaa493-3162-4b89-af34-a79c0cff9abd" />


Recommended view:

* Borrower profile
* Credit score
* Verified repayment history
* Completed loans
* Eligibility
* Evidence/provenance

---

# Credit Intelligence

The current implementation uses a deliberately simple and transparent scoring model.

| Parameter         |               Current Model |
| ----------------- | --------------------------: |
| Initial score     |                         500 |
| Fully repaid loan |                         +15 |
| Maximum score     |                        1000 |
| Partial repayment | Recorded; no score increase |

The current model does not yet incorporate:

* repayment timeliness
* loan size
* loan duration
* default severity
* portfolio behavior
* historical risk weighting

The important architectural property is that the scoring layer consumes **verified financial events**.

---

# Financing Layer

LedgerLine includes a deterministic financing policy demonstrating how verified credit intelligence can be consumed by a downstream financial application.

| Credit Score | Demonstration Eligibility |
| ------------ | ------------------------- |
| `<600`       | Not eligible              |
| `600–749`    | Up to 50%                 |
| `750–899`    | Up to 65%                 |
| `900–1000`   | Up to 80%                 |

Eligibility is additionally capped by cumulative verified repayment activity.

This policy is a demonstration of infrastructure consumption, not a universal underwriting standard.

---

# Security Model

LedgerLine follows a fail-closed architecture.

The verification boundary validates:

* Configured source chain
* Cryptographic proof
* Successful source transaction
* Expected event signature
* Authorized source contract
* Previously unprocessed query
* Proven receipt data

If a required condition fails, the state-changing operation reverts.

### Security Properties

**Invalid proofs**

A failed proof cannot be dispatched into the credit registry.

**Failed source transactions**

A transaction that did not successfully execute cannot become a valid credit event.

**Unauthorized emitters**

A valid transaction from an unrelated contract cannot be interpreted as a LedgerLine financial event.

**Replay**

The same verified query cannot be processed repeatedly to mutate credit state.

**Repayment fragmentation**

Partial repayments do not independently increase the credit score under the current scoring model.

---

# Testing

LedgerLine uses Foundry.

Run:

```bash
forge build
forge test -vvv
```

Current suite:

```text
34 tests passed
0 failed
0 skipped
```

### Test breakdown

```text
LedgerLineSourceRegistryTest       9 passed
LedgerLineSourceSettlementTest     4 passed
LedgerLineReadabilityManagerTest   6 passed
LedgerLineFinancingTest           10 passed
LedgerLineRegistryTest              5 passed
──────────────────────────────────────
TOTAL                              34 passed
```

The suite covers:

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

# Product Model

LedgerLine is designed around three primary participants.

### Borrowers

Borrowers build verifiable repayment history that can potentially become portable across lending environments.

### Lenders

Lenders can use verified repayment history as an additional input when evaluating borrowers.

### Credit Protocols

Credit protocols can consume verified credit information without requiring the original source-chain application to become a trusted reporting intermediary.

This positions LedgerLine as a **credit verification and reputation rail**, rather than simply a standalone scoring dashboard.

---

# Real-World Applications

The same verification architecture can support:

* SME financing
* Merchant credit
* Invoice financing
* Trade finance
* Cross-border lending
* Supply-chain finance
* Embedded lending
* Alternative credit underwriting
* Cross-chain credit markets

The underlying model remains:

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

# Long-Term Product Direction

LedgerLine is designed to become **chain-agnostic financial infrastructure**.

Ethereum Sepolia is the current demonstration environment, not a permanent limitation.

### Phase 1 — Cross-Chain Credit Proofs

Current:

* Ethereum Sepolia integration
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

### Phase 2 — Multi-Chain Credit History

Extend LedgerLine to additional source chains supported by the underlying verification infrastructure.

### Phase 3 — Lender Infrastructure

Build production-facing infrastructure for:

* Borrower credit profiles
* Verified repayment history
* Proof provenance
* Eligibility rules
* Risk signals
* Financing workflows

### Phase 4 — Advanced Credit Intelligence

Introduce additional verified signals such as:

* Repayment timeliness
* Loan size
* Loan duration
* Default history
* Portfolio behavior
* Historical performance

### Phase 5 — Production Credit Network

Build toward an interoperable credit network where lenders and financing protocols can consume verified repayment reputation across multiple financial environments.

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
* Current financing policy is deterministic and experimental

These limitations are explicitly documented rather than hidden.

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
│   └── DEMO.md
│
└── frontend/
```

---

# Documentation

| Document                    | Purpose                                    |
| --------------------------- | ------------------------------------------ |
| `ARCHITECTURE.md`           | Protocol architecture and design decisions |
| `ATTESTCOIN_INTEGRATION.md` | Proof-generation and verification flow     |
| `CREDIT_SCORING_MODEL.md`   | Scoring mechanics                          |
| `DEPLOYMENT.md`             | Deployment and testnet operations          |
| `TESTING.md`                | Test strategy and coverage                 |
| `THREAT_MODEL.md`           | Security assumptions and attack surfaces   |
| `PRODUCT.md`                | Product, users, workflows, and use cases   |
| `WHITEPAPER.md`             | Protocol thesis and long-term architecture |
| `DEMO.md`                   | Reproducible hackathon demonstration       |

---

# Technical Resources

**Source Code**

The complete LedgerLine smart-contract implementation, tests, deployment scripts, frontend, and integration documentation are publicly available.

**GitHub:**
`https://github.com/anjolagithub/ledgerline-core`



**Demo Video:**
`https://youtu.be/k0E1hrLPCcg`

**Whitepaper:**
`(https://drive.google.com/file/d/11JIgG94gfGMZA4yNKwoiqmo9JyDYNaaP/view?usp=sharing)`


---

# Hackathon

**BUIDL CTC 2026 Fall**

**Track:** RWA

**Core Infrastructure:** Creditcoin + Attestcoin Protocol

LedgerLine uses Attestcoin as a fundamental component of its cross-chain verification architecture rather than as a peripheral integration.

---

# Originality

LedgerLine's contracts were written specifically for this project.

The architecture was informed by Creditcoin's public Attestcoin documentation and examples.

LedgerLine's:

* credit registry
* scoring engine
* financing layer
* source-chain loan lifecycle
* verification boundary
* application architecture

were developed as components of this project.

No claim is made that the project reproduces or copies proprietary implementation code.

---

# License

MIT
