#!/usr/bin/env bash
# Send a Telegram notification for a cloud-burst milestone. Best-effort:
# never fails the caller's job if Telegram is unreachable or unconfigured
# (compute must never depend on a notification succeeding).
#
# Setup (one-time, by a human, NOT by this script):
#   1. Telegram -> search @BotFather -> /newbot -> follow prompts -> copy
#      the token it gives you (looks like 123456789:AAExample-Token).
#   2. Open a chat with your new bot and send it any message (e.g. "hi")
#      -- a bot cannot message you until you have messaged it first.
#   3. Find your chat id: open, in a browser,
#      https://api.telegram.org/bot<TOKEN>/getUpdates
#      and read the "chat":{"id": ...} field from the reply.
#   4. NEVER commit the token or chat id to git. Export them as
#      environment variables on the VM only, e.g. over SSH:
#        export TELEGRAM_BOT_TOKEN='123456789:AAExample-Token'
#        export TELEGRAM_CHAT_ID='987654321'
#      or pass them inline when invoking a script that sources this file.
#
# Usage: source this file, then call:  notify "<level>" "<message>"
#   level is a free-form tag for your own log reading, e.g. INFO/WARN/DONE.
# Or invoke directly: ./telegram_notify.sh "<level>" "<message>"

notify() {
  local level="$1" message="$2"
  local ts
  ts="$(date -u +%FT%TZ)"

  # Always append to the local events log, even if Telegram isn't set up --
  # this is the "quy" for the post-mortem regardless of whether the phone
  # alert worked.
  local events_log="${WORK_ROOT:-$HOME/picorv32_burst}/events.log"
  mkdir -p "$(dirname "$events_log")" 2>/dev/null
  printf '%s | %s | %s\n' "$ts" "$level" "$message" >> "$events_log"

  if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "[WARN] TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID not set -- notify() logged locally only: [$level] $message"
    return 0
  fi

  curl -s -m 10 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=[picorv32-burst][$level] $message (at $ts UTC)" \
    > /dev/null \
    || echo "[WARN] Telegram notify failed (network?) -- event still in $events_log: [$level] $message"

  return 0
}

# Allow direct invocation: ./telegram_notify.sh INFO "message here"
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  notify "${1:?Usage: telegram_notify.sh <level> <message>}" "${2:?message required}"
fi
