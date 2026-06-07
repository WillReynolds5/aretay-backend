#!/usr/bin/env bash
#
# Aretay backend helper — wraps the Supabase CLI for local dev and migrations.

set -euo pipefail
cd "$(dirname "$0")"

# ── colours ────────────────────────────────────────────────────────────────
B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'

usage() {
  cat <<EOF
${B}Aretay backend${N} — wraps the Supabase CLI.

${B}Usage:${N}
  ./run-backend.sh <command> [args]

${B}Local stack:${N}
  start              Boot local Supabase (Postgres + Auth + Studio in Docker)
  stop               Shut down local stack
  restart            stop + start
  status             Show URLs and keys for the running local stack
  keys               Print the SUPABASE_URL + SUPABASE_ANON_KEY for Secrets.xcconfig

${B}Migrations:${N}
  new <name>         Create a new timestamped migration file
  up                 Apply pending migrations to the local DB
  reset              Drop + re-create local DB and re-apply all migrations

${B}Remote (after \`link\`):${N}
  link <project-ref> Link to a remote Supabase project (one-time)
  push               Push local migrations to the linked remote project

  help               Show this message
EOF
}

require_supabase() {
  if ! command -v supabase >/dev/null 2>&1; then
    printf "${R}error:${N} supabase CLI not found. Install with: brew install supabase/tap/supabase\n"
    exit 1
  fi
}

require_docker() {
  if ! docker info >/dev/null 2>&1; then
    printf "${R}error:${N} Docker is not running. Open Docker Desktop and try again.\n"
    exit 1
  fi
}

# Print SUPABASE_URL + SUPABASE_ANON_KEY in xcconfig-paste-ready form.
# xcconfig treats // as a comment so we escape it as /\$()/
print_xcconfig_keys() {
  local api_url anon_key xcconfig_url
  api_url=$(supabase status -o env 2>/dev/null | grep '^API_URL=' | cut -d'"' -f2)
  anon_key=$(supabase status -o env 2>/dev/null | grep '^ANON_KEY=' | cut -d'"' -f2)

  if [[ -z "$api_url" || -z "$anon_key" ]]; then
    printf "${R}error:${N} could not read local Supabase status. Is the stack running? Try: ./run-backend.sh start\n"
    exit 1
  fi

  xcconfig_url="${api_url/:\/\//:\/\$()\/}"

  printf "\n${B}Paste into aretay-ios/Config/Secrets.xcconfig:${N}\n\n"
  printf "  ${D}SUPABASE_URL = %s${N}\n"      "$xcconfig_url"
  printf "  ${D}SUPABASE_ANON_KEY = %s${N}\n\n" "$anon_key"
}

cmd_start() {
  require_supabase
  require_docker
  supabase start
  printf "\n${G}✔${N} Local Supabase is up.\n"
  print_xcconfig_keys
}

cmd_stop() {
  require_supabase
  supabase stop
}

cmd_restart() { cmd_stop; cmd_start; }

cmd_reset() {
  require_supabase
  require_docker
  supabase db reset
  printf "\n${G}✔${N} Database reset and migrations re-applied.\n"
}

cmd_status() {
  require_supabase
  supabase status
}

cmd_keys() {
  require_supabase
  print_xcconfig_keys
}

cmd_new() {
  require_supabase
  if [[ $# -lt 1 ]]; then
    printf "${R}error:${N} migration name required.\n  example: ./run-backend.sh new add_concept_fields\n"
    exit 1
  fi
  supabase migration new "$1"
}

cmd_up() {
  require_supabase
  supabase migration up
}

cmd_push() {
  require_supabase
  supabase db push
}

cmd_link() {
  require_supabase
  if [[ $# -lt 1 ]]; then
    printf "${R}error:${N} project ref required. Find it at https://supabase.com/dashboard\n"
    exit 1
  fi
  supabase link --project-ref "$1"
}

main() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    start)            cmd_start ;;
    stop)             cmd_stop ;;
    restart)          cmd_restart ;;
    reset)            cmd_reset ;;
    status)           cmd_status ;;
    keys)             cmd_keys ;;
    new)              cmd_new "$@" ;;
    up)               cmd_up ;;
    push)             cmd_push ;;
    link)             cmd_link "$@" ;;
    help|-h|--help|"") usage ;;
    *)                printf "${R}unknown command:${N} %s\n\n" "$cmd"; usage; exit 1 ;;
  esac
}

main "$@"
