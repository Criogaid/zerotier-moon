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
# auto detect IPs
# -------------------------
if [ -z "${ipv4_address+x}" ]; then
  log "IPv4 unset, auto detecting"
  ipv4_address=$(curl -s https://api.ipify.org || true)
fi

if [ -z "${ipv6_address+x}" ]; then
  log "IPv6 unset, auto detecting"
  ipv6_address=$(curl -s https://api6.ipify.org || true)
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

/usr/sbin/zerotier-idtool genmoon "$ZT_DIR/moon.json" >/dev/null

mkdir -p "$ZT_DIR/moons.d"
mv *.moon "$ZT_DIR/moons.d/"

pkill zerotier-one || true

moon_id=$(grep '"id"' "$ZT_DIR/moon.json" | cut -d '"' -f4)
echo "Moon ID: $moon_id"
echo "Orbit command: zerotier-cli orbit $moon_id $moon_id"

exec /usr/sbin/zerotier-one
