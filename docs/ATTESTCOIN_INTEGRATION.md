# LedgerLine — Attestcoin Integration

## 1. Purpose

Attestcoin is the cryptographic evidence layer behind LedgerLine.

LedgerLine does not update credit state merely because an off-chain service says that a repayment occurred.

Instead, the source-chain transaction is proven and verified before it can influence the credit registry.

## 2. End-to-end flow

```text
1. Source transaction
       ↓
2. Source block
       ↓
3. Creditcoin attestation
       ↓
4. Proof generation
       ↓
5. LedgerLineProofVerifier
       ↓
6. Native Block Prover
       ↓
7. Receipt decoding
       ↓
8. Authorized event verification
       ↓
9. LedgerLineRegistry
       ↓
10. Credit profile update
```

## 3. Source transaction

The source-chain contracts emit three canonical events.

### LoanRegistered

Emitted by:

```text
LedgerLineSourceRegistry
```

Contains:

* loan ID
* lender
* borrower
* loan amount
* expected repayment
* deadline

### LoanFunded

Emitted by:

```text
LedgerLineSourceSettlement
```

Contains:

* loan ID
* lender
* borrower
* funding amount

### LoanRepaid

Emitted by:

```text
LedgerLineSourceSettlement
```

Contains:

* loan ID
* repayment amount

## 4. Relayer

The TypeScript relayer is implemented in:

```text
script/flow/submitProofsToHub.ts
```

The relayer:

1. retrieves the source transaction
2. obtains its block number
3. waits for attestation
4. generates a proof
5. submits the proof to the ReadabilityManager
6. waits for the Creditcoin transaction

The relayer does not directly modify credit state.

## 5. Proof generation

The proof generator returns:

```text
headerNumber
txBytes
merkleProof
continuityProof
```

These values are passed directly into:

```solidity
LedgerLineReadabilityManager.submitProof(...)
```

## 6. Native verification

`LedgerLineProofVerifier` calls:

```text
0x0000000000000000000000000000000000000FD2
```

through the Attestcoin proof-verifier interface.

The verification result must explicitly succeed.

Failure causes the transaction to revert.

## 7. Transaction status

A valid Merkle proof alone is not enough.

LedgerLine also checks that the proven receipt has:

```text
status == 1
```

A cryptographically proven failed transaction therefore cannot update credit state.

## 8. Authorized emitters

The manager is configured with:

```text
authorizedSourceRegistry
authorizedSourceSettlement
```

The expected event must come from the correct contract.

For example:

```text
LoanRegistered
        ↓
SourceRegistry only
```

and:

```text
LoanRepaid
        ↓
SourceSettlement only
```

This prevents arbitrary contracts from producing matching events and injecting them into the credit system.

## 9. Event decoding

The manager uses:

```text
LedgerLineDecoder
```

to decode the proven receipt.

The system identifies:

* event signature
* topics
* event data
* emitting address

The credit registry is then updated using the decoded values.

## 10. Replay protection

Every proof submission creates a query identifier derived from the source chain, block height and transaction bytes.

Previously processed queries are rejected.

This prevents the same repayment proof from being submitted repeatedly.

## 11. Demonstrated live flow

A real Sepolia demonstration produced:

```text
LoanRegistered
0xff0d3efc1eac63f918a185578222855f8918532640f43503962f6ee960bc0078

LoanFunded
0x8f56d40f0e9370fab7c0e30e8c1fb2a7079a3761d4b42c56a5d904187adb097e

LoanRepaid
0x45f46804615af83b450ab78f2485ef95e8dfc21702d7f506c1f7749564af00da
```

The corresponding transactions are passed through the Attestcoin proof pipeline before being dispatched into the Creditcoin registry.

## 12. Security property

The essential security property is:

```text
No proof
    → no dispatch

Invalid proof
    → no dispatch

Failed transaction
    → no dispatch

Wrong emitter
    → no dispatch

Unknown event
    → no dispatch

Previously processed proof
    → no dispatch
```

Only a valid, proven, successful and authorized source event can influence credit state.
