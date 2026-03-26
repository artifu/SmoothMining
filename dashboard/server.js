const fs = require("fs");
const http = require("http");
const path = require("path");

const rootDir = path.resolve(__dirname, "..");
const envPath = path.join(rootDir, ".env");
const monitorPath = path.join(rootDir, "logs", "xmrig-monitor.csv");

function loadEnv() {
  const env = {};

  if (!fs.existsSync(envPath)) {
    return env;
  }

  const lines = fs.readFileSync(envPath, "utf8").split(/\r?\n/);
  for (const line of lines) {
    if (!line || line.trim().startsWith("#")) {
      continue;
    }

    const separator = line.indexOf("=");
    if (separator === -1) {
      continue;
    }

    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    env[key] = value;
  }

  return env;
}

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseCsv(filePath) {
  if (!fs.existsSync(filePath)) {
    return [];
  }

  const lines = fs.readFileSync(filePath, "utf8").trim().split(/\r?\n/);
  if (lines.length <= 1) {
    return [];
  }

  const headers = lines[0].split(",");
  return lines.slice(1).map((line) => {
    const values = line.split(",");
    const row = {};
    headers.forEach((header, index) => {
      row[header] = values[index] ?? "";
    });
    return row;
  });
}

function json(res, status, payload) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(payload));
}

function text(res, status, payload, contentType = "text/plain; charset=utf-8") {
  res.writeHead(status, { "Content-Type": contentType });
  res.end(payload);
}

function serveStatic(req, res) {
  const requestPath = req.url === "/" ? "/index.html" : req.url;
  const filePath = path.join(__dirname, requestPath);

  if (!filePath.startsWith(__dirname) || !fs.existsSync(filePath)) {
    text(res, 404, "Not found");
    return;
  }

  const ext = path.extname(filePath);
  const contentType =
    ext === ".html"
      ? "text/html; charset=utf-8"
      : ext === ".js"
        ? "application/javascript; charset=utf-8"
        : ext === ".css"
          ? "text/css; charset=utf-8"
          : "text/plain; charset=utf-8";

  text(res, 200, fs.readFileSync(filePath), contentType);
}

function extractHashrate(summary) {
  const candidates = [
    summary?.hashrate?.total,
    summary?.hashrate?.threads,
    summary?.miner?.hashrate?.total,
    summary?.miner?.hashrate,
  ];

  for (const candidate of candidates) {
    if (Array.isArray(candidate)) {
      return {
        h10s: toNumber(candidate[0]),
        h60s: toNumber(candidate[1]),
        h15m: toNumber(candidate[2]),
      };
    }
  }

  return null;
}

async function fetchXmrigSummary(env) {
  const host = env.XMRIG_HTTP_HOST || "127.0.0.1";
  const port = env.XMRIG_HTTP_PORT || "18080";
  const token = env.XMRIG_HTTP_TOKEN || "";
  const paths = ["/1/summary", "/2/summary", "/summary"];

  for (const requestPath of paths) {
    try {
      const result = await new Promise((resolve, reject) => {
        const req = http.request(
          {
            host,
            port,
            path: requestPath,
            method: "GET",
            timeout: 1500,
            headers: token ? { Authorization: `Bearer ${token}` } : {},
          },
          (res) => {
            let body = "";
            res.setEncoding("utf8");
            res.on("data", (chunk) => {
              body += chunk;
            });
            res.on("end", () => {
              if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
                try {
                  resolve(JSON.parse(body));
                } catch (error) {
                  reject(error);
                }
              } else {
                reject(new Error(`XMRig API status ${res.statusCode}`));
              }
            });
          }
        );

        req.on("error", reject);
        req.on("timeout", () => req.destroy(new Error("XMRig API timeout")));
        req.end();
      });

      return result;
    } catch (_error) {
      continue;
    }
  }

  return null;
}

function buildEconomics(env, hashrateHps) {
  const networkHashrate = toNumber(env.NETWORK_HASHRATE_HPS, 1100000000);
  const xmrPriceUsd = toNumber(env.XMR_PRICE_USD, 145);
  const powerWatts = toNumber(env.ESTIMATED_POWER_WATTS, 18);
  const electricityCost = toNumber(env.ELECTRICITY_COST_PER_KWH, 0.18);

  const xmrPerDay = networkHashrate > 0 ? (hashrateHps / networkHashrate) * 432 : 0;
  const revenueUsdPerDay = xmrPerDay * xmrPriceUsd;
  const powerCostUsdPerDay = (powerWatts / 1000) * 24 * electricityCost;

  return {
    assumptions: {
      networkHashrateHps: networkHashrate,
      xmrPriceUsd,
      powerWatts,
      electricityCostPerKwh: electricityCost,
    },
    estimates: {
      xmrPerDay,
      revenueUsdPerDay,
      powerCostUsdPerDay,
      netUsdPerDay: revenueUsdPerDay - powerCostUsdPerDay,
    },
  };
}

const server = http.createServer(async (req, res) => {
  const env = loadEnv();

  if (req.url === "/api/config") {
    json(res, 200, {
      dashboardPort: toNumber(env.DASHBOARD_PORT, 4173),
      estimatedPowerWatts: toNumber(env.ESTIMATED_POWER_WATTS, 18),
      electricityCostPerKwh: toNumber(env.ELECTRICITY_COST_PER_KWH, 0.18),
      xmrPriceUsd: toNumber(env.XMR_PRICE_USD, 145),
      networkHashrateHps: toNumber(env.NETWORK_HASHRATE_HPS, 1100000000),
    });
    return;
  }

  if (req.url === "/api/monitor") {
    const rows = parseCsv(monitorPath);
    json(res, 200, { rows: rows.slice(-240) });
    return;
  }

  if (req.url === "/api/status") {
    const summary = await fetchXmrigSummary(env);
    const hashrate = extractHashrate(summary);
    const lastHashrate = hashrate?.h60s || hashrate?.h10s || hashrate?.h15m || 0;
    const economics = buildEconomics(env, lastHashrate);

    json(res, 200, {
      connected: Boolean(summary),
      summary,
      hashrate,
      economics,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  serveStatic(req, res);
});

const env = loadEnv();
const port = toNumber(env.DASHBOARD_PORT, 4173);

server.listen(port, "127.0.0.1", () => {
  console.log(`SmoothMining dashboard running at http://127.0.0.1:${port}`);
});

