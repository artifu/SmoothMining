# macOS Setup

## Install dependencies

```bash
brew install xmrig cpulimit
```

## Configure local environment

```bash
cp .env.example .env
```

Edit `.env` and set:

- `WALLET_ADDRESS` to your Monero receive subaddress
- `POOL_URL` to your chosen pool
- `THREADS` to a conservative value such as `2`
- `CPU_LIMIT` to a conservative value such as `50`

## Run the miner safely

```bash
bash scripts/run_xmrig.sh
```

## First-run guidance

- Start with low thread counts.
- Watch CPU usage and temperature before extending runtime.
- Stop immediately if the machine becomes too hot, noisy, or unresponsive.
