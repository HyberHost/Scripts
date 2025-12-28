#!/usr/bin/env bash
set -euo pipefail

############################  USER CONFIG  ############################
OUTPUT="email"                # email | slack | discord | none
EMAIL_TO="raid@example.com"   # Email address for alerts
CRITICAL_THRESHOLD=1          # how many failed arrays before alert
VERBOSE=0
JSON=0
HELP=0
TEST=0
#####################################################################

log_verbose() {
  if [[ $VERBOSE -eq 1 ]]; then
    echo "[VERBOSE] $*" >&2
  fi
}


# Server identification
SERVER_HOSTNAME="$(hostname)"
SERVER_LAN="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "Unknown")"
SERVER_WAN="$(curl -fsS https://api.ipify.org || echo "Unknown")"
log_verbose "Server Hostname: $SERVER_HOSTNAME"
log_verbose "Server LAN IP: $SERVER_LAN"
log_verbose "Server WAN IP: $SERVER_WAN"

######################## Argument parsing ########################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      [[ -n "${2:-}" ]] || { echo "--output requires a value" >&2; exit 2; }
      OUTPUT="$2"
      shift 2
      ;;
    --emailto)
      [[ -n "${2:-}" ]] || { echo "--emailto requires a value" >&2; exit 2; }
      EMAIL_TO="$2"
      shift 2
      ;;
    --critical-threshold|--critical)
      [[ -n "${2:-}" ]] || { echo "--critical requires a value" >&2; exit 2; }
      CRITICAL_THRESHOLD="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -j|--json)
      JSON=1
      shift
      ;;
    -h|--help)
      HELP=1
      shift
      ;;
    --test)
      TEST=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

######################## Help ########################
if [[ $HELP -eq 1 ]]; then
  cat >&2 <<EOF
Usage: $0 [options]

Options:
  --output email|slack|discord|none
  --emailto EMAIL
  --critical N
  -v, --verbose
  -j, --json
  --test
  -h, --help
EOF
  exit 0
fi

######################## mdstat ########################
MDSTAT_FILE="/proc/mdstat"
if [[ ! -r "$MDSTAT_FILE" ]]; then
  echo "Error: Cannot read $MDSTAT_FILE" >&2
  exit 3
fi

mdstat_content=$(cat "$MDSTAT_FILE")

######################## Test mode ########################
if [[ $TEST -eq 1 ]]; then
  log_verbose "Test mode enabled: injecting degraded array"
  mdstat_content+="
md999 : active raid1 sda1[0] sdb1[1]
      100000 blocks super 1.2 [2/1] [U_]
"
fi

######################## RAID parsing ########################
degraded_arrays=()

while read -r header; do
  arr_name=$(awk '{print $1}' <<<"$header")
  status_line=$(grep -A1 "^$arr_name" <<<"$mdstat_content" | tail -n1)

  log_verbose "Checking $arr_name"
  log_verbose "Status: $status_line"

  # Detect [total/active]
  if [[ "$status_line" =~ \[([0-9]+)/([0-9]+)\] ]]; then
    total=${BASH_REMATCH[1]}
    active=${BASH_REMATCH[2]}
    if (( active < total )); then
      degraded_arrays+=("$arr_name")
      log_verbose "$arr_name degraded ($active/$total)"
    fi
  fi

  # Detect missing disks like [U_] or [_U]
  if [[ "$status_line" =~ \[[U_]+\] ]] && [[ "$status_line" != *"[UU]"* ]]; then
    degraded_arrays+=("$arr_name")
    log_verbose "$arr_name missing disk indicator"
  fi

  # Detect resync / recovery / faulty
  if grep -qiE 'resync|recovery|degraded|faulty' <<<"$status_line"; then
    degraded_arrays+=("$arr_name")
    log_verbose "$arr_name resync/recovery/faulty detected"
  fi

done <<< "$(grep '^md[0-9]' <<<"$mdstat_content")"

######################## Results ########################
unique_degraded=($(printf "%s\n" "${degraded_arrays[@]}" | sort -u))

if [[ ${#unique_degraded[@]} -ge $CRITICAL_THRESHOLD ]]; then
  status="PROBLEM"
  msg="RAID problem: ${unique_degraded[*]} degraded\nServer: $SERVER_HOSTNAME\nLAN IP: $SERVER_LAN\nWAN IP: $SERVER_WAN"
  email_subject="RAID ALERT: $SERVER_HOSTNAME - ${unique_degraded[*]} degraded"
  exitcode=1
else
  status="OK"
  arrays=$(grep '^md[0-9]' <<<"$mdstat_content" | awk '{print $1}' | paste -sd ', ' -)
  msg="OK: ${arrays:-no arrays found}\nServer: $SERVER_HOSTNAME\nLAN IP: $SERVER_LAN\nWAN IP: $SERVER_WAN"
  exitcode=0
fi

######################## Output ########################
if [[ $JSON -eq 1 ]]; then
  printf '{"status":"%s","arrays":"%s","message":"%s"}\n' \
    "$status" "${unique_degraded[*]}" "$msg"
elif [[ $VERBOSE -eq 1 ]]; then
  echo "$mdstat_content"
  echo "$msg"
else
  echo "$msg"
fi

######################## Alerts ########################
if [[ $exitcode -eq 1 ]]; then
  if [[ "$OUTPUT" == "email" ]]; then
    if command -v mail >/dev/null 2>&1; then
      echo -e "$mdstat_content\n\n$msg" | mail -s "$email_subject" "$EMAIL_TO"
      log_verbose "Email sent to $EMAIL_TO"
    else
      echo "mail command not found, cannot send email" >&2
    fi
  elif [[ "$OUTPUT" == "none" ]]; then
    :
  elif [[ -x "$OUTPUT" ]]; then
    "$OUTPUT" --message "$msg" --details "$mdstat_content"
  else
    echo "Unknown output method: $OUTPUT" >&2
  fi
fi

exit $exitcode
