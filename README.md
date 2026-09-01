# LedgerLine

**Proof-backed credit infrastructure for the real economy.**

LedgerLine is a cross-chain credit infrastructure protocol that turns verified repayment activity into portable on-chain credit intelligence.

A loan can originate and settle on a source chain such as Ethereum Sepolia while the resulting credit record is maintained on Creditcoin. Instead of trusting a centralized oracle, spreadsheet, API response, or borrower declaration, LedgerLine uses Creditcoin's Attestcoin Protocol to cryptographically prove that the source-chain transaction actually occurred.

The verified event is then decoded and dispatched into LedgerLine's on-chain credit registry.

## The core idea

> **Proof before credit.**

LedgerLine separates financial activity from credit intelligence.

A source chain records what happened.

Attestcoin proves what happened.

LedgerLine records the resulting credit history.

This creates a verifiable path:

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
        ├── event decoding
        └── replay protection
        │
        ▼
LedgerLineRegistry
        │
        ▼
Verified borrower credit profile
```

## What LedgerLine solves

Financial activity frequently exists across multiple chains, platforms, and systems.

A lender may originate or settle a loan on one network while another institution needs reliable evidence of the borrower's repayment history somewhere else.

Traditional approaches introduce trust assumptions:

* centralized credit databases
* self-reported repayment history
* spreadsheets
* API-based attestations
* manually verified bank statements
* centralized oracles

LedgerLine instead makes the evidence itself verifiable.

A credit score can only change after the underlying repayment transaction has been cryptographically proven.

## Current implementation

LedgerLine currently demonstrates:

* Ethereum Sepolia as the source chain
* Creditcoin CC3 Testnet as the credit-intelligence chain
* Attestcoin transaction proof verification
* native Creditcoin Block Prover precompile integration
* verified source-chain event decoding
* authorized source-contract validation
* replay protection
* on-chain loan lifecycle tracking
* repayment-based credit scoring
* lender eligibility checks
* invoice-financing policy consumption
* live read access from the frontend

The source-chain contracts intentionally remain minimal. The credit intelligence and scoring logic lives on Creditcoin.

## Contracts

### Ethereum Sepolia

**LedgerLineSourceRegistry**

Registers loan terms and emits the canonical `LoanRegistered` event.

**LedgerLineSourceSettlement**

Handles source-chain loan funding and repayment transfers and emits:

* `LoanFunded`
* `LoanRepaid`

### Creditcoin CC3 Testnet

**LedgerLineProofVerifier**

Thin wrapper around Creditcoin's native Block Prover precompile.

**LedgerLineReadabilityManager**

The trust boundary of the system.

It:

1. receives a proof
2. verifies the proof
3. verifies source-chain transaction success
4. verifies the expected event
5. verifies the authorized emitter
6. prevents replay
7. decodes the proven receipt
8. dispatches the verified event

**LedgerLineRegistry**

The credit-intelligence layer.

It maintains:

* loan lifecycle state
* verified repayment totals
* completed-loan count
* borrower credit score
* last update timestamp

**LedgerLineFinancing**

A downstream consumer of the credit registry.

It applies a deterministic underwriting policy to verified credit data.

## Deployed testnet contracts

| Contract                     | Network                | Address                                      |
| ---------------------------- | ---------------------- | -------------------------------------------- |
| LedgerLineSourceRegistry     | Ethereum Sepolia       | `0x1Af3D4ED1D2592DdAD9c13A3004006c9785eC6fF` |
| LedgerLineSourceSettlement   | Ethereum Sepolia       | `0xa00DeE06b5d8DD4889683d2d526a744C2Bd67297` |
| LedgerLineRegistry           | Creditcoin CC3 Testnet | `0xde8365dAF3CFdF952E2F946F19a4DcAcd57eFf0F` |
| LedgerLineProofVerifier      | Creditcoin CC3 Testnet | `0x859Cab6e9912ee39efD71f5957ecf0c61CB64494` |
| LedgerLineReadabilityManager | Creditcoin CC3 Testnet | `0xCC0B4686de40Ff5ae1e0B8d58Da9175e9090610D` |
| LedgerLineFinancing          | Creditcoin CC3 Testnet | See deployment output / broadcast artifact   |

## Live demonstration flow

The repository includes an end-to-end source-chain flow.

The demo:

1. mints demonstration stablecoin funds
2. registers a loan
3. funds the loan
4. repays the loan
5. obtains the resulting transaction hashes
6. waits for Creditcoin attestation
7. generates Attestcoin proofs
8. submits the proofs to Creditcoin
9. verifies the transactions on-chain
10. updates the LedgerLine credit registry

The latest demonstrated source transactions are:

```text
LoanRegistered
0xff0d3efc1eac63f918a185578222855f8918532640f43503962f6ee960bc0078

LoanFunded
0x8f56d40f0e9370fab7c0e30e8c1fb2a7079a3761d4b42c56a5d904187adb097e

LoanRepaid
0x45f46804615af83b450ab78f2485ef95e8dfc21702d7f506c1f7749564af00da
```

These hashes represent the source-chain side of the demonstration. The corresponding Attestcoin proof submission is performed by `script/flow/submitProofsToHub.ts`.

## Credit scoring

LedgerLine currently uses a deliberately simple and transparent model.

Initial score:

```text
500
```

A borrower receives:

```text
+15 points
```

when a loan is fully repaid.

The score is capped at:

```text
1000
```

Partial repayments increase verified repayment volume but do not increase the credit score.

This prevents a borrower from artificially increasing their score by splitting a single obligation into many tiny repayments.

See:

`docs/CREDIT_SCORING_MODEL.md`

## Financing layer

LedgerLineFinancing consumes the registry's verified credit metrics.

Current policy:

| Score    | Completed loans | Advance rate |
| -------- | --------------: | -----------: |
| < 600    |             any | Not eligible |
| 600–749  |             ≥ 1 |          50% |
| 750–899  |             ≥ 1 |          65% |
| 900–1000 |             ≥ 1 |          80% |

The resulting advance is additionally capped by the borrower's cumulative verified repayments.

This financing contract is intentionally separated from the core verification and scoring engine.

## Security model

LedgerLine is designed to fail closed.

The ReadabilityManager does not simply accept a claim that a repayment occurred.

Before dispatching an event, it requires:

* a configured source chain
* successful cryptographic proof verification
* a successful source transaction
* the expected event signature
* the expected authorized source contract
* a previously unprocessed query

If any of these conditions fail, the transaction reverts.

See:

`docs/THREAT_MODEL.md`

## Testing

The repository contains a Foundry test suite covering the core contracts, including fuzz testing.

Run:

```bash
forge build
forge test -vv
```

The current repository test suite reports:

```text
24/24 passing
```

## Deployment

See:

`docs/DEPLOYMENT.md`

## Documentation

* `docs/ARCHITECTURE.md` — protocol architecture and design decisions
* `docs/ATTESTCOIN_INTEGRATION.md` — proof-generation and verification flow
* `docs/CREDIT_SCORING_MODEL.md` — scoring mechanics
* `docs/THREAT_MODEL.md` — security assumptions and attack surfaces
* `docs/DEPLOYMENT.md` — deployment and testnet operations
* `docs/TESTING.md` — test strategy and coverage
* `docs/PRODUCT.md` — product, users, workflows and use cases
* `docs/WHITEPAPER.md` — protocol thesis and long-term architecture
* `docs/DEMO.md` — reproducible hackathon demonstration

## Frontend

The LedgerLine frontend is maintained as a separate application and consumes the deployed contracts through public RPC endpoints.

The frontend currently provides:

* network status
* wallet connection
* credit-profile queries
* verification lifecycle visualization
* repayment/audit views
* lender workspace
* borrower workspace
* invoice-financing demonstration
* developer-facing contract information

The frontend deliberately distinguishes live blockchain reads from demonstration data.

Sample invoice records and illustrative underwriting values are not presented as real customer data.

## Current limitations

LedgerLine is a hackathon/testnet implementation.

Known limitations include:

* Creditcoin CC3 Testnet deployment
* Ethereum Sepolia source chain
* single configured source chain per ReadabilityManager instance
* simplified credit scoring
* no negative score adjustment for defaults yet
* no production KYB/KYC system
* financing execution is not yet connected to a production capital provider
* invoice registry data in the frontend remains demonstrative
* production-grade relayer infrastructure is still required

These are documented limitations rather than hidden assumptions.

## Originality

LedgerLine's contracts were written specifically for this project.

The system architecture was informed by Creditcoin's public Attestcoin documentation and examples, but the LedgerLine credit-scoring engine and financing layer are original components of the project.

## License

MIT
