# Wallet Setup

## Recommendation

Use an official self-custody Monero wallet and create a dedicated receive subaddress for mining payouts.

## Why this approach

- It keeps exchange accounts out of the mining loop.
- It gives you a stable payout address that you control.
- It reduces the chance of payout issues caused by unsupported assets or exchange deposit policies.

## What to store in this repository

- Public wallet receive subaddress: acceptable in local `.env` only.
- Seed phrase: never store it here.
- Private keys: never store them here.
- Exchange credentials: never store them here.

## Workflow

1. Install the official Monero GUI wallet on your machine.
2. Create or restore your wallet.
3. Generate a new receive subaddress dedicated to mining.
4. Copy that public subaddress into your local `.env` file as `WALLET_ADDRESS`.
5. Keep your seed phrase offline and backed up securely.

