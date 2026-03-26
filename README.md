# SmoothMining

An educational low-impact Monero mining project focused on safe CPU limits, reproducible setup, and strong public documentation.

## Overview

SmoothMining is a portfolio-oriented repository for experimenting with CPU mining on personal hardware in a controlled way. The project wraps a real miner workflow around XMRig while keeping the operational posture conservative: low thread counts, explicit CPU limits, local wallet ownership, and a clean setup that can be documented and benchmarked.

The goal is to learn how mining software behaves on a normal machine, not to maximize profit. This repository is designed to show practical engineering judgment around system safety, automation, and observability.

## Goals

- Run XMRig with conservative defaults suitable for background use.
- Keep configuration simple and reproducible through local environment variables.
- Separate safe-to-commit project files from machine-specific secrets and runtime settings.
- Build a benchmarkable workflow that can later add metrics, charts, and findings.
- Present the project professionally for GitHub and recruiter review.

## Non-Goals

- Optimizing for real mining profitability.
- Running aggressive workloads on laptops or thermally constrained machines.
- Using exchange logins, seed phrases, or private keys inside the repository.
- Encouraging unauthorized mining on third-party infrastructure.

## Repository Layout

```text
.
├── README.md
├── .env.example
├── configs/
│   └── xmrig.example.json
├── dashboard/
│   ├── index.html
│   └── server.js
├── docs/
│   ├── setup-macos.md
│   └── wallet-setup.md
└── scripts/
    ├── start_all.sh
    ├── start_dashboard.sh
    ├── start_xmrig_background.sh
    ├── stop_all.sh
    ├── monitor_xmrig.sh
    └── run_xmrig.sh
```

## Recommended Wallet Flow

Use an official self-custody Monero wallet and create a dedicated receive subaddress for mining payouts.

Why this is the best fit for this project:

- You fully control the payout address.
- You avoid exchange-specific asset support issues.
- You keep private material outside the repo and outside the miner configuration.

This project only needs a public receive address. Never store your seed phrase, private keys, or exchange credentials in this repository.

## Quick Start

1. Install dependencies on macOS:

   ```bash
   brew install xmrig cpulimit
   ```

2. Create your local config:

   ```bash
   cp .env.example .env
   ```

3. Edit `.env` and set your values:

   - `WALLET_ADDRESS`: your Monero receive subaddress
   - `POOL_URL`: your chosen mining pool
   - `THREADS`: start low, such as `2`
   - `CPU_LIMIT`: start conservatively, such as `50`

4. Run the safe wrapper:

   ```bash
   bash scripts/run_xmrig.sh
   ```

5. Start the lightweight monitor in another terminal:

   ```bash
   bash scripts/monitor_xmrig.sh
   ```

6. Start the local dashboard:

   ```bash
   bash scripts/start_dashboard.sh
   ```

7. Open the local page:

   ```text
   http://127.0.0.1:4173
   ```

## One-Command Control

Start everything in the background:

```bash
bash scripts/start_all.sh
```

Start everything with a custom monitor interval:

```bash
bash scripts/start_all.sh 30
```

Stop everything cleanly:

```bash
bash scripts/stop_all.sh
```

Background logs:

- `logs/xmrig.log`
- `logs/monitor.log`
- `logs/dashboard.log`

## Safe Defaults

The starter script is intentionally conservative:

- Lower process priority through `nice`
- CPU throttling through `cpulimit` when available
- Small thread count by default
- No secrets committed to version control
- Lightweight CSV logging for background observation
- Local-only miner API for dashboarding on `127.0.0.1`

## Safety Notes

- Mining can increase heat, fan noise, and long-term hardware wear.
- Start with short runs and verify temperatures manually.
- Stop immediately if the machine becomes unstable, too hot, or heavily throttled.
- Expect educational value to be much higher than economic return on consumer CPUs.

## Documentation

- Wallet setup: `docs/wallet-setup.md`
- macOS setup: `docs/setup-macos.md`
- Example XMRig config: `configs/xmrig.example.json`
- Runtime monitor output: `logs/xmrig-monitor.csv`
- Local dashboard: `dashboard/index.html`

## Next Steps

1. Add a metrics collection script for CPU load, temperature, and runtime logs.
2. Add benchmark result templates under `benchmarks/`.
3. Generate charts comparing hashrate, CPU limit, and thermal behavior.
4. Publish findings and lessons learned in the repository.
