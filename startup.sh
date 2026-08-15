#!/bin/sh
# usage: ./startup.sh -4 1.2.3.4 -6 2001:abcd:abcd::1 -p 9993

set -e
set -f

ZT_DIR=/var/lib/zerotier-one
BOOTSTRAP_TIMEOUT=60
BOOTSTRAP_STOP_TIMEOUT=5
moon_port=9993
ipv4_explicit=false
ipv6_explicit=false
bootstrap_pid=
moon_tmp_dir=

mkztfile() {
  file=$1
  mode=$2
  content=$3

  mkdir -p "$ZT_DIR"
  printf '%s\n' "$content" > "$ZT_DIR/$file"
  chmod "$mode" "$ZT_DIR/$file"
}

log() {
  echo "=> $*"
}

log_detail() {
  echo "===> $*"
}

stop_bootstrap() {
  [ -n "$bootstrap_pid" ] || return 0
  kill "$bootstrap_pid" 2>/dev/null || true
  stop_waited=0
  while kill -0 "$bootstrap_pid" 2>/dev/null \
    && [ "$stop_waited" -lt "$BOOTSTRAP_STOP_TIMEOUT" ]; do
    sleep 1
    stop_waited=$((stop_waited + 1))
  done
  if kill -0 "$bootstrap_pid" 2>/dev/null; then
    log "Bootstrap did not stop after ${BOOTSTRAP_STOP_TIMEOUT}s; killing it"
    kill -KILL "$bootstrap_pid" 2>/dev/null || true
  fi
  wait "$bootstrap_pid" 2>/dev/null || true
  bootstrap_pid=
}

cleanup() {
  stop_bootstrap
  [ -z "$moon_tmp_dir" ] || rm -rf "$moon_tmp_dir"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

is_ipv4() {
  case "$1" in */*) return 1 ;; esac
  ipcalc -4 -c "$1" >/dev/null 2>&1
}

is_ipv6() {
  case "$1" in */*) return 1 ;; esac
  ipcalc -6 -c "$1" >/dev/null 2>&1
}

while getopts "4:6:p:" arg; do
  case "$arg" in
    4) ipv4_address=$OPTARG; ipv4_explicit=true ;;
    6) ipv6_address=$OPTARG; ipv6_explicit=true ;;
    p) moon_port=$OPTARG ;;
    *) exit 1 ;;
  esac
done

case "$moon_port" in
  ''|*[!0-9]*)
    echo "Error: Invalid port number: [$moon_port]" >&2
    exit 1
    ;;
esac

if [ "${#moon_port}" -gt 5 ] || [ "$moon_port" -lt 1 ] || [ "$moon_port" -gt 65535 ]; then
  echo "Error: Port number must be between 1 and 65535, got: $moon_port" >&2
  exit 1
fi

mkdir -p "$ZT_DIR"

[ -z "${ZEROTIER_API_SECRET:-}" ] || mkztfile authtoken.secret 0600 "$ZEROTIER_API_SECRET"
[ -z "${ZEROTIER_IDENTITY_PUBLIC:-}" ] || mkztfile identity.public 0644 "$ZEROTIER_IDENTITY_PUBLIC"
[ -z "${ZEROTIER_IDENTITY_SECRET:-}" ] || mkztfile identity.secret 0600 "$ZEROTIER_IDENTITY_SECRET"

# 旧 endpoint 仅用于自动探测失败时的持久化回退。
existing_config_valid=false
existing_ipv4_endpoints='[]'
existing_ipv6_endpoints='[]'
if [ -s "$ZT_DIR/moon.json" ] \
  && jq -e '.stableEndpoints | arrays | all(.[]; type == "string")' "$ZT_DIR/moon.json" >/dev/null 2>&1; then
  existing_config_valid=true
  existing_ipv4_endpoints=$(jq -c --arg port "$moon_port" \
    '[.stableEndpoints[] | select(contains(":") | not) | sub("/[0-9]+$"; "/" + $port)]' \
    "$ZT_DIR/moon.json")
  existing_ipv6_endpoints=$(jq -c --arg port "$moon_port" \
    '[.stableEndpoints[] | select(contains(":")) | sub("/[0-9]+$"; "/" + $port)]' \
    "$ZT_DIR/moon.json")
fi

ipv4_endpoints='[]'
if [ "$ipv4_explicit" = true ]; then
  if [ -n "${ipv4_address:-}" ]; then
    if ! is_ipv4 "$ipv4_address"; then
      echo "Error: Invalid IPv4 address: [$ipv4_address]" >&2
      exit 1
    fi
    ipv4_endpoints=$(jq -cn --arg endpoint "$ipv4_address/$moon_port" '[$endpoint]')
  fi
else
  log "IPv4 unset, auto detecting"
  ipv4_address=$(wget -qO- -T 10 https://api.ipify.org | tr -d '[:space:]' || true)
  if [ -n "$ipv4_address" ] && is_ipv4 "$ipv4_address"; then
    ipv4_endpoints=$(jq -cn --arg endpoint "$ipv4_address/$moon_port" '[$endpoint]')
  elif [ "$existing_config_valid" = true ] && [ "$existing_ipv4_endpoints" != '[]' ]; then
    log "IPv4 detection failed; preserving persisted endpoint"
    ipv4_endpoints=$existing_ipv4_endpoints
  else
    [ -z "$ipv4_address" ] || log "Ignoring invalid auto-detected IPv4: [$ipv4_address]"
  fi
fi

ipv6_endpoints='[]'
if [ "$ipv6_explicit" = true ]; then
  if [ -n "${ipv6_address:-}" ]; then
    if ! is_ipv6 "$ipv6_address"; then
      echo "Error: Invalid IPv6 address: [$ipv6_address]" >&2
      exit 1
    fi
    ipv6_endpoints=$(jq -cn --arg endpoint "$ipv6_address/$moon_port" '[$endpoint]')
  fi
else
  log "IPv6 unset, auto detecting"
  ipv6_address=$(wget -qO- -T 10 https://api6.ipify.org | tr -d '[:space:]' || true)
  if [ -n "$ipv6_address" ] && is_ipv6 "$ipv6_address"; then
    ipv6_endpoints=$(jq -cn --arg endpoint "$ipv6_address/$moon_port" '[$endpoint]')
  elif [ "$existing_config_valid" = true ] && [ "$existing_ipv6_endpoints" != '[]' ]; then
    log "IPv6 detection failed; preserving persisted endpoint"
    ipv6_endpoints=$existing_ipv6_endpoints
  else
    [ -z "$ipv6_address" ] || log "Ignoring invalid auto-detected IPv6: [$ipv6_address]"
  fi
fi

stable_endpoints=$(jq -cn \
  --argjson ipv4 "$ipv4_endpoints" \
  --argjson ipv6 "$ipv6_endpoints" \
  '$ipv4 + $ipv6')

if [ "$stable_endpoints" = '[]' ]; then
  echo "Error: No IPv4 or IPv6 endpoint available" >&2
  exit 1
fi

log "StableEndpoints: $stable_endpoints"

mkdir -p "$ZT_DIR/networks.d"
if [ -n "${ZEROTIER_JOIN_NETWORKS:-}" ]; then
  log "Joining networks: $ZEROTIER_JOIN_NETWORKS"
  for network_id in $ZEROTIER_JOIN_NETWORKS; do
    if ! printf '%s\n' "$network_id" | grep -qE '^[0-9A-Fa-f]{16}$'; then
      echo "Error: Invalid ZeroTier network ID: [$network_id]" >&2
      exit 1
    fi
    log_detail "join $network_id"
    touch "$ZT_DIR/networks.d/$network_id.conf"
  done
fi

# 首次启动仅用于生成 identity；失败必须退出，让容器重启策略接管。
if [ ! -s "$ZT_DIR/identity.secret" ] || [ ! -s "$ZT_DIR/identity.public" ]; then
  log "Generating ZeroTier identity"
  /usr/sbin/zerotier-one &
  bootstrap_pid=$!
  waited=0

  while [ ! -s "$ZT_DIR/identity.secret" ] || [ ! -s "$ZT_DIR/identity.public" ]; do
    if ! kill -0 "$bootstrap_pid" 2>/dev/null; then
      if wait "$bootstrap_pid"; then
        bootstrap_status=0
      else
        bootstrap_status=$?
      fi
      bootstrap_pid=
      echo "Error: ZeroTier exited before generating identity (status $bootstrap_status)" >&2
      exit 1
    fi
    if [ "$waited" -ge "$BOOTSTRAP_TIMEOUT" ]; then
      echo "Error: Timed out after ${BOOTSTRAP_TIMEOUT}s waiting for ZeroTier identity" >&2
      exit 1
    fi
    sleep 1
    waited=$((waited + 1))
  done

  stop_bootstrap
fi

moon_id=$(cut -d: -f1 "$ZT_DIR/identity.public")
if ! printf '%s\n' "$moon_id" | grep -qE '^[0-9A-Fa-f]{10}$'; then
  echo "Error: Invalid ZeroTier identity.public" >&2
  exit 1
fi

moon_file="$ZT_DIR/moons.d/000000${moon_id}.moon"
regenerate=false
old_moon_id=
if [ "$existing_config_valid" = true ]; then
  old_moon_id=$(jq -r '.id // empty' "$ZT_DIR/moon.json")
  existing_stable_endpoints=$(jq -c '.stableEndpoints' "$ZT_DIR/moon.json")
  [ "$old_moon_id" = "$moon_id" ] || regenerate=true
  [ "$existing_stable_endpoints" = "$stable_endpoints" ] || regenerate=true
else
  regenerate=true
fi
[ -s "$moon_file" ] || regenerate=true

if [ "$regenerate" = true ]; then
  log "Generating Moon configuration"
  moon_tmp_dir=$(mktemp -d "$ZT_DIR/.moon-setup.XXXXXX")
  /usr/sbin/zerotier-idtool initmoon "$ZT_DIR/identity.public" \
    | jq -e --argjson stable_endpoints "$stable_endpoints" \
        '.stableEndpoints = $stable_endpoints' > "$moon_tmp_dir/moon.json"

  generated_moon_id=$(jq -er '.id' "$moon_tmp_dir/moon.json")
  if [ "$generated_moon_id" != "$moon_id" ]; then
    echo "Error: Generated Moon ID does not match identity" >&2
    exit 1
  fi

  (cd "$moon_tmp_dir" && /usr/sbin/zerotier-idtool genmoon moon.json >/dev/null)
  generated_moon="$moon_tmp_dir/000000${moon_id}.moon"
  if [ ! -s "$generated_moon" ]; then
    echo "Error: zerotier-idtool did not generate $generated_moon" >&2
    exit 1
  fi

  mkdir -p "$ZT_DIR/moons.d"
  mv -f "$generated_moon" "$moon_file"
  if [ -n "$old_moon_id" ] && [ "$old_moon_id" != "$moon_id" ] \
    && printf '%s\n' "$old_moon_id" | grep -qE '^[0-9A-Fa-f]{10}$'; then
    rm -f "$ZT_DIR/moons.d/000000${old_moon_id}.moon"
  fi
  mv -f "$moon_tmp_dir/moon.json" "$ZT_DIR/moon.json"
  rmdir "$moon_tmp_dir"
  moon_tmp_dir=
else
  log "Moon configuration is current"
fi

echo "Moon ID: $moon_id"
echo "Orbit command: zerotier-cli orbit $moon_id $moon_id"

trap - EXIT INT TERM
exec /usr/sbin/zerotier-one
