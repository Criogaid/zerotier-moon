#!/bin/sh
# usage ./startup.sh -4 1.2.3.4 -6 2001:abcd:abcd::1 -p 9993

set -e

ZT_DIR=/var/lib/zerotier-one
moon_port=9993

# -------------------------
# helper functions
# -------------------------
mkztfile() {
  file=$1
  mode=$2
  content=$3

  mkdir -p "$ZT_DIR"
  echo "$content" > "$ZT_DIR/$file"
  chmod "$mode" "$ZT_DIR/$file"
}

log() {
  echo "=> $*"
}

log_detail() {
  echo "===> $*"
}

killzerotier() {
  log "Killing zerotier"
  [ -f "$ZT_DIR/zerotier-one.pid" ] && kill "$(cat "$ZT_DIR/zerotier-one.pid")" 2>/dev/null || true
  exit 0
}

trap killzerotier INT TERM

# -------------------------
# args
# -------------------------
while getopts "4:6:p:" arg; do
  case "$arg" in
    4) ipv4_address="$OPTARG" ;;
    6) ipv6_address="$OPTARG" ;;
    p) moon_port="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

# -------------------------
# clean and validate args
# -------------------------
# Remove any whitespace from arguments
ipv4_address=$(echo "$ipv4_address" | tr -d '[:space:]')
ipv6_address=$(echo "$ipv6_address" | tr -d '[:space:]')
moon_port=$(echo "$moon_port" | tr -d '[:space:]')

# Validate port number
if ! echo "$moon_port" | grep -qE '^[0-9]+$'; then
  echo "Error: Invalid port number: [$moon_port]"
  exit 1
fi

if [ "$moon_port" -lt 1 ] || [ "$moon_port" -gt 65535 ]; then
  echo "Error: Port number must be between 1 and 65535, got: $moon_port"
  exit 1
fi

# -------------------------
# auto detect IPs
# -------------------------
if [ -z "${ipv4_address+x}" ]; then
  log "IPv4 unset, auto detecting"
  ipv4_address=$(curl -s https://api.ipify.org | tr -d '[:space:]' || true)
fi

if [ -z "${ipv6_address+x}" ]; then
  log "IPv6 unset, auto detecting"
  ipv6_address=$(curl -s https://api6.ipify.org | tr -d '[:space:]' || true)
fi

if [ -z "$ipv4_address" ] && [ -z "$ipv6_address" ]; then
  echo "No IPv4 or IPv6 available"
  exit 1
fi

# -------------------------
# build stableEndpoints JSON
# -------------------------
stable_endpoints=""

if [ -n "$ipv4_address" ]; then
  stable_endpoints="\"$ipv4_address/$moon_port\""
fi

if [ -n "$ipv6_address" ]; then
  [ -n "$stable_endpoints" ] && stable_endpoints="$stable_endpoints,"
  stable_endpoints="$stable_endpoints\"$ipv6_address/$moon_port\""
fi

# Debug information
log "Debug: ipv4_address=[$ipv4_address]"
log "Debug: ipv6_address=[$ipv6_address]"
log "Debug: moon_port=[$moon_port]"
log "StableEndpoints: [$stable_endpoints]"

# -------------------------
# identity / secrets
# -------------------------
[ -n "$ZEROTIER_API_SECRET" ]       && mkztfile authtoken.secret 0600 "$ZEROTIER_API_SECRET"
[ -n "$ZEROTIER_IDENTITY_PUBLIC" ]  && mkztfile identity.public 0644 "$ZEROTIER_IDENTITY_PUBLIC"
[ -n "$ZEROTIER_IDENTITY_SECRET" ]  && mkztfile identity.secret 0600 "$ZEROTIER_IDENTITY_SECRET"

# -------------------------
# networks
# -------------------------
mkdir -p "$ZT_DIR/networks.d"

if [ -n "$ZEROTIER_JOIN_NETWORKS" ]; then
  log "Joining networks: $ZEROTIER_JOIN_NETWORKS"
  for n in $ZEROTIER_JOIN_NETWORKS; do
    log_detail "join $n"
    touch "$ZT_DIR/networks.d/$n.conf"
  done
fi

# -------------------------
# moon setup
# -------------------------
if [ -d "$ZT_DIR/moons.d" ]; then
  moon_id=$(cut -d ':' -f1 "$ZT_DIR/identity.public")
  echo "Moon ID: $moon_id"
  exec /usr/sbin/zerotier-one
fi

# first start to generate identity
nohup /usr/sbin/zerotier-one >/dev/null 2>&1 &
while [ ! -f "$ZT_DIR/identity.secret" ]; do
  sleep 1
done

/usr/sbin/zerotier-idtool initmoon "$ZT_DIR/identity.public" > "$ZT_DIR/moon.json"

sed -i "s#\"stableEndpoints\": \[\]#\"stableEndpoints\": [$stable_endpoints]#g" \
  "$ZT_DIR/moon.json"

# Verify sed replacement was successful
if grep -q '"stableEndpoints": \[\]' "$ZT_DIR/moon.json"; then
  log "Error: Failed to update stableEndpoints in moon.json"
  log "This usually happens when stableEndpoints format is unexpected"
  log "Contents of moon.json:"
  cat "$ZT_DIR/moon.json"
  exit 1
fi

log "Successfully updated moon.json with stableEndpoints"

/usr/sbin/zerotier-idtool genmoon "$ZT_DIR/moon.json" >/dev/null

mkdir -p "$ZT_DIR/moons.d"
mv *.moon "$ZT_DIR/moons.d/"

pkill zerotier-one || true

moon_id=$(grep '"id"' "$ZT_DIR/moon.json" | cut -d '"' -f4)
echo "Moon ID: $moon_id"
echo "Orbit command: zerotier-cli orbit $moon_id $moon_id"

exec /usr/sbin/zerotier-one
