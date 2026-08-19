# LedgerLine — Deployment Guide

## Prerequisites

- Foundry installed, `forge build` passing locally
- A funded wallet on both Sepolia and Creditcoin CC3 Testnet
- `.env` populated (see `.env.example`)

## Known environment quirks

- **CC3 Testnet requires `--legacy`.** Foundry's default simulation expects
  post-Merge header fields (`prevrandao`) that CC3 testnet doesn't populate.
  Fix: pin `evm_version = "london"` in `foundry.toml` and always deploy with
  `--legacy`.
- **`forge script --broadcast` can partially fail on CC3 testnet** without a
  clear top-level error, even after real transactions succeed — verify every
  deployment step independently with `cast call` rather than trusting the
  script's own success message alone.
- **TypeScript scripts need CommonJS, not ESM**, given this project's
  `ts-node` setup — run with plain `npx ts-node file.ts`, no `--esm` flag.

## Deploy order

```bash
# 1. Source chain (Sepolia)
forge script script/DeploySource.s.sol --rpc-url sepolia --broadcast --legacy -vvvv

# 2. Demo token, for testing flows (Sepolia)
forge script script/DeployDemoToken.s.sol --rpc-url sepolia --broadcast --legacy -vvvv

# 3. Hub chain (CC3 Testnet)
forge script script/DeployHub.s.sol --rpc-url cc3_testnet --broadcast --legacy -vvvv
```

If only the manager needs redeploying (interface changes, bug fixes):
```bash
forge script script/RedeployManager.s.sol --rpc-url cc3_testnet --broadcast --legacy -vvvv
```

## Verifying a deployment actually landed

```bash
cast call <MANAGER_ADDRESS> "sourceChainKey()(bytes32)" --rpc-url cc3_testnet
cast call <REGISTRY_ADDRESS> "hasRole(bytes32,address)(bool)" <READABILITY_ROLE_HASH> <MANAGER_ADDRESS> --rpc-url cc3_testnet
```
Both must return non-zero/true before the system is considered live.

## Running the full flow

```bash
npx ts-node script/flow/runSourceFlow.ts
# copy the printed events JSON
npx ts-node script/flow/submitProofsToHub.ts '<paste JSON>'
cast call <REGISTRY_ADDRESS> "getCreditProfile(address)((uint16,uint256,uint256,uint256))" <BORROWER_ADDRESS> --rpc-url cc3_testnet
```
