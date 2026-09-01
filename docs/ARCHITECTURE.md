# LedgerLine Architecture

## 1. Overview

LedgerLine is a cross-chain credit infrastructure protocol.

Its purpose is to transform verifiable financial activity on one blockchain into portable credit intelligence on another blockchain.

The current implementation uses:

* Ethereum Sepolia as the source environment
* Creditcoin CC3 Testnet as the destination credit-intelligence environment
* Creditcoin Attestcoin Protocol for source-chain transaction proofs

The central architectural principle is:

> LedgerLine does not trust the message. LedgerLine verifies the evidence behind the message.

## 2. High-level architecture

```text
                         OFF-CHAIN
                  ┌─────────────────────┐
                  │ LedgerLine Relayer  │
                  │                     │
                  │ wait for attestation│
                  │ generate proof      │
                  │ submit proof        │
                  └──────────┬──────────┘
                             │
                             │ proof
                             ▼

┌───────────────────────┐       ┌──────────────────────────────┐
│ Ethereum Sepolia      │       │ Creditcoin CC3 Testnet       │
│                       │       │                              │
│ SourceRegistry        │       │ ProofVerifier                │
│ SourceSettlement      │──────►│ ReadabilityManager           │
│                       │ proof │                              │
│ LoanRegistered        │       │ Registry                     │
│ LoanFunded            │       │ Financing                    │
│ LoanRepaid            │       │                              │
└───────────────────────┘       └──────────────────────────────┘
```

## 3. Source-chain layer

### LedgerLineSourceRegistry

The source registry records the terms of a loan and emits a canonical event.

Responsibilities:

* lender allowlisting
* loan ID generation
* borrower validation
* token validation
* amount validation
* deadline validation
* `LoanRegistered` event emission

It deliberately does not maintain the full loan lifecycle.

### LedgerLineSourceSettlement

The settlement contract handles actual token movement.

Responsibilities:

* loan funding
* loan repayment
* ERC20 transfers
* settlement event emission

Events:

```solidity
LoanFunded(
    uint256 indexed loanId,
    address indexed lender,
    address indexed borrower,
    uint256 amount
)
```

```solidity
LoanRepaid(
    uint256 indexed loanId,
    uint256 amount
)
```

The contract is intentionally minimal.

## 4. Attestation layer

The source transaction is not directly trusted by Creditcoin.

The off-chain relayer waits for the source block to become attested by the Attestcoin infrastructure.

The relayer then requests:

* encoded transaction bytes
* Merkle inclusion proof
* continuity proof

The resulting proof package is passed to the hub-chain verification contract.

## 5. Proof verification

### LedgerLineProofVerifier

`LedgerLineProofVerifier` is intentionally thin.

It wraps Creditcoin's native Block Prover precompile:

```text
0x0000000000000000000000000000000000000FD2
```

The contract does not reinterpret the proof.

It asks the native verifier whether the supplied transaction proof is valid.

If verification fails, the call reverts.

## 6. ReadabilityManager

`LedgerLineReadabilityManager` is the protocol's main security boundary.

It orchestrates:

```text
proof
 ↓
native verification
 ↓
transaction status
 ↓
event signature
 ↓
authorized emitter
 ↓
receipt decoding
 ↓
dispatch
```

### Source-chain binding

Each manager instance is bound to one source chain:

```text
sourceChainKey
authorizedSourceRegistry
authorizedSourceSettlement
```

This means a proof from an unrelated chain or contract cannot simply be injected into the same manager.

## 7. Replay protection

Each submitted proof receives a deterministic query ID:

```text
keccak256(
    sourceChainKey,
    blockHeight,
    encodedTransaction
)
```

The manager records processed query IDs.

A previously processed proof cannot be dispatched again.

## 8. Event verification

The manager recognizes three actions:

```text
LoanRegistered
LoanFunded
LoanRepaid
```

Each action maps to a specific event signature.

The manager also determines which source contract is allowed to emit that event.

Therefore:

```text
Correct event + wrong contract
        =
      REVERT
```

This is important because merely matching an event signature is insufficient.

## 9. Receipt decoding

After proof verification, LedgerLine decodes the proven transaction representation.

The decoder extracts:

* transaction status
* receipt logs
* event topics
* event data

The manager then locates the expected event.

The system does not accept a caller-supplied borrower, repayment amount or loan state as authoritative evidence.

Those values are derived from the proven source transaction.

## 10. Credit registry

`LedgerLineRegistry` stores the destination-side credit state.

For each borrower:

```text
score
totalVerifiedRepayments
completedLoanCount
lastUpdated
```

For each loan:

```text
sourceChainKey
sourceLoanId
repayFlow
terms
status
repaidAmount
createdAtBlock
```

The registry can only be mutated by an address holding `READABILITY_ROLE`.

## 11. Loan lifecycle

```text
Created
   │
   ▼
Funded
   │
   ├──────────────► PartlyRepaid
   │                      │
   │                      ▼
   └──────────────────► Repaid
```

A repayment event is processed only when the mirrored loan is in:

```text
Funded
```

or:

```text
PartlyRepaid
```

## 12. Credit scoring

A new borrower begins at:

```text
500
```

A fully completed loan increases the score by:

```text
15
```

The maximum score is:

```text
1000
```

Partial repayments update verified repayment volume but do not increase the score.

## 13. Financing layer

`LedgerLineFinancing` is intentionally downstream from the credit registry.

It does not duplicate credit state.

Instead:

```text
LedgerLineRegistry
       │
       ▼
verified credit metrics
       │
       ▼
LedgerLineFinancing
       │
       ▼
deterministic underwriting decision
```

This separation means the verification system does not need to understand invoices or financing products.

## 14. Trust boundaries

### Trusted

* deployed source contract addresses
* configured source-chain key
* native proof verifier
* access-controlled registry roles
* deployed contract bytecode

### Not trusted

* borrower claims
* lender claims
* frontend values
* off-chain repayment assertions
* arbitrary event emitters
* arbitrary transaction data

### Conditionally trusted

The relayer is trusted only to submit proofs.

It cannot directly change credit scores because it does not possess the registry's write role and cannot bypass proof verification.

## 15. Design principles

### Minimal source-chain logic

The source chain should only record and settle financial activity.

### Verification before interpretation

LedgerLine verifies the underlying transaction before interpreting its contents.

### Fail closed

Invalid or ambiguous evidence causes a revert rather than a best-effort state update.

### Immutable core

The deployed core contracts are not upgradeable proxies.

This strengthens the trust model by preventing silent modification of scoring logic.

### Separation of concerns

Verification, registry state, settlement and financing are separate contracts.

This keeps each component easier to reason about and test.

## 16. Future architecture

The current deployment intentionally supports one source chain per manager.

A production version can extend this model to:

```text
Ethereum
Base
Arbitrum
Optimism
Solana
other supported source environments
        │
        ▼
Attestcoin / proof layer
        │
        ▼
LedgerLine verification layer
        │
        ▼
Portable credit profile
```

The scoring layer can then remain independent of where the underlying repayment occurred.
