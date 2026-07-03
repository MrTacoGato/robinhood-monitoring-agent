# Robinhood Monitoring Agent

An autonomous portfolio-monitoring agent running 24/7 on a repurposed 2012 Mac mini. It reads a brokerage account through an API, runs scheduled research and risk checks, and delivers alerts to a phone via Telegram.

**Read-only by design — it never places, cancels, or modifies a trade.** Execution stays fully human: the agent analyzes and surfaces ideas; a person approves any action separately.

## What it does

- **Every 30 minutes during market hours** — checks holdings for significant intraday drops and alerts on threshold breaches.
- **Each morning before the open** — produces a structured research review: portfolio snapshot, macro/market context, per-holding news, and scored trade ideas.
- **Silent when nothing matters** — no alert spam; it only messages when a real condition is met.
- **Market-aware scheduling** — skips weekends and U.S. market holidays automatically.

## Architecture

| Layer | Tool |
|---|---|
| Hardware | 2012 Mac mini (Intel), rescued from a drawer |
| OS | Ubuntu Server (headless) |
| Agent runtime | Claude Code (Sonnet) |
| Market/account data | Robinhood via MCP (read-only tools only) |
| Scheduling | cron |
| Alerts | Telegram Bot API |

A wrapper script (`monitor.sh`) invokes the agent headless with a strict read-only tool allowlist, applies a task prompt, and pushes any resulting alert to Telegram. Order-execution tools are deliberately **not** loaded in the scheduled path, enforcing the read-only boundary at the system level rather than by instruction alone.

## Safety design

- Scheduled runs load **only** read tools (positions, quotes, fundamentals, market data). No order tool is available to the automated process.
- Secrets (API keys, bot token) live in a local `.env` that is git-ignored. See `.env.example` for the required variables.
- Any real trade requires explicit human approval in an interactive session — never automated.

## Setup

1. Provision Ubuntu Server on the target machine (headless).
2. Install Claude Code and connect the Robinhood MCP.
3. Copy `.env.example` to `.env` and fill in your values.
4. Make the wrapper executable: `chmod +x monitor.sh`
5. Schedule via cron (see the schedule notes in the script).

## Files

- `monitor.sh` — wrapper that runs the agent read-only and sends alerts
- `system_prompt.md` — the analyst role, rules, and safety constraints
- `morning_task.md` — the daily research-review task
- `monitor_task.md` — the intraday drop-check task
- `.env.example` — template for required secrets (no real values)

## Why

Built as a hands-on exercise in headless Linux, API/MCP integration, scheduled automation, and safe-by-design systems — turning 15-year-old hardware into a working always-on service.
