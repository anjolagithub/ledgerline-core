# LedgerLine Threat Model

## 1. Security objective

LedgerLine's primary security objective is to prevent false financial activity from becoming trusted credit history.

The core threat is not merely a hacked frontend.

The core threat is:

```text
False financial event
        ↓
accepted as legitimate
        ↓
credit profile manipulated
        ↓
financing decision affected
```

LedgerLine is designed to break this chain.

## 2. Threat: self-reported repayment

### Attack

A borrower claims to have repaid a loan.

### Mitigation

Credit state cannot be directly updated by the borrower.

Repayment must originate from a source-chain transaction that passes through proof verification.

## 3. Threat: forged event

### Attack

An attacker deploys another contract that emits a `LoanRepaid` event with fabricated data.

### Mitigation

The ReadabilityManager verifies both:

* event signature
* authorized emitting contract

An identical event from an unauthorized address is rejected.

## 4. Threat: invalid source transaction

### Attack

An attacker submits a proof for a reverted source-chain transaction.

### Mitigation

The decoded receipt status must equal:

```text
1
```

Otherwise the transaction reverts.

## 5. Threat: proof replay

### Attack

An attacker repeatedly submits the same valid repayment proof.

### Mitigation

The ReadabilityManager records processed query IDs.

Previously processed queries revert.

## 6. Threat: unauthorized registry writes

### Attack

An attacker directly calls the registry's state-changing functions.

### Mitigation

Registry mutations require:

```text
READABILITY_ROLE
```

The relayer does not receive this role.

## 7. Threat: unauthorized source lender

### Attack

An arbitrary wallet originates fake loans through the source registry.

### Mitigation

The source registry has an owner-controlled lender allowlist.

Only approved lenders can call `registerLoan`.

## 8. Threat: malicious frontend

### Attack

A frontend displays a fabricated credit score.

### Mitigation

The frontend is not the source of truth.

Credit profile data can be read directly from the deployed Creditcoin registry.

The frontend is therefore a presentation layer.

## 9. Threat: compromised relayer

### Attack

The off-chain relayer is compromised.

### Impact

The relayer can submit arbitrary proof packages, but it cannot directly modify registry state.

Invalid proofs fail verification.

The relayer therefore has less authority than the on-chain registry.

## 10. Threat: compromised administrator

The administrator controls important configuration operations, including:

* source-chain configuration
* role administration
* lender allowlisting
* pause controls

This remains a trust assumption.

A production deployment should therefore use:

* multisig administration
* operational separation
* monitoring
* timelocked configuration changes where appropriate

## 11. Threat: malicious source contract

LedgerLine currently trusts explicitly configured source contracts.

If a configured source contract itself contains malicious logic, the system can prove that its transactions occurred but cannot determine whether the underlying business relationship was economically legitimate.

This is an important distinction:

> Cryptographic proof establishes that an on-chain event happened. It does not independently establish that the underlying real-world transaction was commercially honest.

## 12. Threat: economic manipulation

The current score is deliberately simple.

Possible future manipulation vectors include:

* circular lending
* related-party loans
* artificial repayment volume
* low-value loan farming
* coordinated lender/borrower behavior

The current system partially addresses fragmentation by scoring only full loan completion, but economic Sybil resistance requires additional policy and identity controls.

## 13. Threat: frontend demo confusion

The frontend contains demonstration invoice and underwriting records.

These must never be represented as real customer records.

The frontend therefore labels demonstration data as:

```text
DEMO / TESTNET DATA
```

Production versions should replace sample records with authenticated data from actual registries.

## 14. Security posture

LedgerLine's core security strategy is layered:

```text
Access control
     +
Source contract allowlist
     +
Cryptographic proof
     +
Transaction-status validation
     +
Authorized-emitter validation
     +
Receipt decoding
     +
Replay protection
     +
Fail-closed dispatch
```

No single layer is intended to be the complete security model.

## 15. Production hardening

Before mainnet deployment, the following should be added:

* independent smart-contract audit
* multisig administration
* formal verification of critical invariants
* production relayer redundancy
* monitoring and alerting
* rate limiting
* source-contract upgrade governance
* richer default handling
* economic Sybil resistance
* production identity/KYB controls
