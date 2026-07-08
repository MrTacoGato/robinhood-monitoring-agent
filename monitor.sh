#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"
# usage: monitor.sh <task_file> <label>
source ~/.bashrc
set -a; source ~/rh-agent/.env; set +a
cd ~/rh-agent

TASK="$1"
LABEL="$2"

# --- Market-open gate: skip weekends + US market holidays ---
DOW=$(date +%u)
if [ "$DOW" -ge 6 ]; then exit 0; fi
HOLIDAYS="2026-01-01 2026-01-19 2026-02-16 2026-04-03 2026-05-25 2026-06-19 2026-07-03 2026-09-07 2026-11-26 2026-12-25"
TODAY=$(date +%F)
for h in $HOLIDAYS; do
  if [ "$TODAY" = "$h" ]; then exit 0; fi
done
# --- end gate ---

OUT=$(claude -p "$(cat system_prompt.md)

Target account: $RH_ACCOUNT

$(cat $TASK)" \
  --model sonnet \
  --allowedTools "mcp__robinhood__get_accounts" "mcp__robinhood__get_portfolio" "mcp__robinhood__get_equity_positions" "mcp__robinhood__get_option_positions" "mcp__robinhood__get_equity_quotes" "mcp__robinhood__get_index_quotes" "mcp__robinhood__get_indexes" "mcp__robinhood__get_earnings_calendar" "mcp__robinhood__get_equity_fundamentals" "mcp__robinhood__get_earnings_results" "WebSearch" \
  2>>~/rh-agent/error.log)

echo "$(date): [$LABEL] $OUT" >> ~/rh-agent/monitor.log

if [ -n "$OUT" ] && [[ "$OUT" != *"NOALERT"* ]]; then
  printf '%s' "${LABEL}
$OUT" | fold -w 3800 -s | split -l 1 - /tmp/rhmsg_
  for f in /tmp/rhmsg_*; do
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      --data-urlencode chat_id="${TG_CHAT_ID}" \
      --data-urlencode text@"$f" > /dev/null
    sleep 1
  done
  rm -f /tmp/rhmsg_*
fi
