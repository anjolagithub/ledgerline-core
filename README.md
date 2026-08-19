# LedgerLine

**A cross-chain credit-scoring registry, built on Creditcoin's Attestcoin Protocol.**

Built for the BUIDL CTC 2026 Fall hackathon (Creditcoin & Credit Labs), RWA track.

## What it does

A fintech lender registers a loan and funds it on Ethereum Sepolia. When the
borrower repays, LedgerLine doesn't just trust that it happened — it uses
Creditcoin's Attestcoin Protocol to cryptographically verify the repayment
transaction, then automatically updates the borrower's credit score on
Creditcoin, with no centralized oracle and no self-reported data.

**This works end-to-end today, live on testnet** — not a mockup. A real
Sepolia repayment, verified through the real Block Prover precompile, has
updated a real credit profile on Creditcoin CC3 Testnet.

## Why this matters

Real-world lenders often settle repayments on cheaper chains than the one
investors actually track. That leaves investors trusting a spreadsheet.
LedgerLine replaces that trust with proof: a credit score that only moves
when a repayment is cryptographically verified, not claimed.

## Architecture

[ Ethereum Sepolia ] [ Creditcoin CC3 Testnet ]

LedgerLineSourceRegistry LedgerLineProofVerifier
LedgerLineSourceSettlement ──proof──► LedgerLineReadabilityManager
LedgerLineRegistry (scoring)


Full breakdown in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Deployed addresses

| Contract | Chain | Address |
|---|---|---|
| LedgerLineSourceRegistry | Sepolia | `0x1Af3D4ED1D2592DdAD9c13A3004006c9785eC6fF` |
| LedgerLineSourceSettlement | Sepolia | `0xa00DeE06b5d8DD4889683d2d526a744C2Bd67297` |
| LedgerLineRegistry | CC3 Testnet | `0xde8365dAF3CFdF952E2F946F19a4DcAcd57eFf0F` |
| LedgerLineProofVerifier | CC3 Testnet | `0x859Cab6e9912ee39efD71f5957ecf0c61CB64494` |
| LedgerLineReadabilityManager | CC3 Testnet | `0xCC0B4686de40Ff5ae1e0B8d58Da9175e9090610D` |

## Quickstart

```bash
git clone <this repo>
cd ledgerline
forge install
forge build
forge test -vv    # 24/24 passing
```

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — system design and rationale
- [`docs/ATTESTCOIN_INTEGRATION.md`](docs/ATTESTCOIN_INTEGRATION.md) — how the protocol integration actually works
- [`docs/CREDIT_SCORING_MODEL.md`](docs/CREDIT_SCORING_MODEL.md) — the scoring algorithm and why
- [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) — known risks and mitigations, including one caught by our own test suite
- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — deploy steps and environment quirks
- [`docs/TESTING.md`](docs/TESTING.md) — test coverage breakdown

## A note on originality

LedgerLine's contracts were written from scratch for this hackathon. Design
patterns (proof verification flow, replay protection, minimal source-chain
logic) were informed by Creditcoin's own public documentation and reference
examples, as recommended by the hackathon's developer resources — but no
code was copied. The credit-scoring engine (`LedgerLineRegistry`) has no
equivalent in any reference material; it's original to this project.

## License

MIT
