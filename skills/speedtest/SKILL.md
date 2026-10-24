---
name: speedtest
description: Measure this machine's internet connection (download, upload, latency, jitter, packet loss) with Speedtest by Ookla. Use when asked to test the internet speed or bandwidth, check whether the connection is slow, or compare servers or network interfaces.
allowed-tools: Bash(command -v speedtest) Bash(speedtest *)
---

# Testing the internet connection

This skill uses Ookla's official CLI, `speedtest`, installed in
`~/.local/bin` (see `~/.config/erinos/tools.md`). If `command -v speedtest` finds
nothing, use the install-cli skill to install "speedtest by ookla". Do not
use the Python `speedtest-cli` package, which is a different tool.

## 1. Run the test

```
speedtest -f json -p no
```

- `-f json` prints one JSON object on stdout. `-p no` turns off the progress bar.
- One test takes about 30 seconds and transfers several hundred MB. Give the
  Bash call a timeout of at least 120000 ms. Run one test per request unless
  asked for more; if comparing, run them one after another, never in parallel.
- Once the license and GDPR notice have been accepted, they are stored in
  `~/.config/ookla/speedtest-cli.json`. If that file is gone, the command
  stops at a license prompt. Tell the user, and add
  `--accept-license --accept-gdpr` only if they agree to the terms.

Options worth knowing:

| Need | Flag |
|------|------|
| List nearby servers (fast, no test) | `-L` (add `-f json` to parse) |
| Use a specific server | `-s <id>` or `-o <host>` |
| Test through one network interface | `-I <name>` (for example `wlp192s0`) |
| Test from one local IP | `-i <address>` |
| Explain how the server was chosen | `--selection-details` |
| Diagnose a failing test | `-v`, `-vv`, `-vvv` |

## 2. Read the result

Bandwidth values are in **bytes per second**. Multiply by 8 and divide by
1,000,000 to get Mbps. Every time is in milliseconds.

| Field | Meaning |
|-------|---------|
| `download.bandwidth`, `upload.bandwidth` | Throughput, bytes/s |
| `ping.latency`, `ping.jitter` | Idle latency and jitter, ms |
| `download.latency.iqm`, `upload.latency.iqm` | Latency under load, ms (bufferbloat) |
| `packetLoss` | Percent; the field may be missing when it could not be measured |
| `isp`, `server.name`, `server.location`, `server.id` | Who was tested against |
| `interface.name`, `interface.isVpn` | Which link carried the test |
| `result.url` | Ookla's page for this result |

## 3. Report

Lead with download and upload in Mbps, then idle latency, jitter and packet
loss, then the server and interface used. Mention latency under load if it
is much higher than idle latency, since that signals bufferbloat. Do not
repeat the internal or external IP or the MAC address unless asked.

Ookla keeps every result (`result.persisted: true`), and anyone with
`result.url` can open it. Include the link only if the user wants it.

## Errors

On failure the command exits non-zero and prints a JSON line with
`"type":"log","level":"error"`. Report its `message`. Common causes: an
invalid server id (`NoServersException`), no network, or an interface name
that does not exist. Retry once with a different server from `-L` before
concluding the connection is down.
