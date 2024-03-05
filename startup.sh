#!/bin/sh

# usage ./startup.sh -4 1.2.3.4 -6 2001:abcd:abcd::1 -p 9993

grepzt() {
  [ -f /var/lib/zerotier-one/zerotier-one.pid -a -n "$(cat /var/lib/zerotier-one/zerotier-one.pid 2>/dev/null)" -a -d "/proc/$(cat /var/lib/zerotier-one/zerotier-one.pid 2>/dev/null)" ]
  return $?
}

mkztfile() {
  file=$1
  mode=$2
  content=$3

  mkdir -p /var/lib/zerotier-one
  echo "$content" > "/var/lib/zerotier-one/$file"
  chmod "$mode" "/var/lib/zerotier-one/$file"
}

moon_port=9993 # default ZeroTier moon port

# handle args
while getopts "4:6:p:" arg; do
  case $arg in
  4)
    ipv4_address="$OPTARG"
    echo "IPv4 address: $ipv4_address"
    ;;
  6)
    ipv6_address="$OPTARG"
    echo "IPv6 address: $ipv6_address"
    ;;
  p)
    moon_port="$OPTARG"
    echo "Moon port: $moon_port"
    ;;
  ?)
    echo "unknown argument"
    exit 1
    ;;
  esac
done

if [ -z ${ipv4_address+x} ]; then
  echo "IPv4 address is unset, automatically catch the IPv4 address"
  ipv4_address=$(curl -s https://api.ipify.org)
  if [ -n "$ipv4_address" ]; then
    echo "IPv4 address is set to '$ipv4_address'"
  else
    echo "Failed to catch the IPv4 address, please set IPv4 address manually."
    unset ipv4_address
  fi
fi

if [ -z ${ipv6_address+x} ]; then
  echo "IPv6 address is unset, automatically catch the IPv6 address"
  ipv6_address=$(curl -s https://api6.ipify.org)
  if [ -n "$ipv6_address" ]; then
    echo "IPv6 address is set to '$ipv6_address'"
  else
    echo "Failed to catch the IPv6 address."
    unset ipv6_address
  fi
fi

stableEndpointsForSed=""
if [ -z ${ipv4_address+x} ]; then # ipv4 address is not set
  if [ -z ${ipv6_address+x} ]; then # ipv6 address is not set
    echo "Please set IPv4 address or IPv6 address."
    exit 0
  else # ipv6 address is set
    stableEndpointsForSed="\"$ipv6_address\/$moon_port\""
  fi
else # ipv4 address is set
  if [ -z ${ipv6_address+x} ]; then # ipv6 address is not set
    stableEndpointsForSed="\"$ipv4_address\/$moon_port\""
  else # ipv6 address is set
    stableEndpointsForSed="\"$ipv4_address\/$moon_port\",\"$ipv6_address\/$moon_port\""
  fi
fi

killzerotier() {
  log "Killing zerotier"
  kill $(cat /var/lib/zerotier-one/zerotier-one.pid 2>/dev/null)
  exit 0
}

log_header() {
  echo -n "\r=>"
}

log_detail_header() {
  echo -n "\r===>"
}

log() {
  echo "$(log_header)" "$@"
}

log_params() {
  title=$1
  shift
  log "$title" "[$@]"
}

log_detail() {
  echo "$(log_detail_header)" "$@"
}

log_detail_params() {
  title=$1
  shift
  log_detail "$title" "[$@]"
}

if [ "x$ZEROTIER_API_SECRET" != "x" ]
then
  mkztfile authtoken.secret 0600 "$ZEROTIER_API_SECRET"
fi

if [ "x$ZEROTIER_IDENTITY_PUBLIC" != "x" ]
then
  mkztfile identity.public 0644 "$ZEROTIER_IDENTITY_PUBLIC"
fi

if [ "x$ZEROTIER_IDENTITY_SECRET" != "x" ]
then
  mkztfile identity.secret 0600 "$ZEROTIER_IDENTITY_SECRET"
fi

trap killzerotier INT TERM

log "Configuring networks to join"
mkdir -p /var/lib/zerotier-one/networks.d

if [ "x$ZEROTIER_JOIN_NETWORKS" != "x" ]
then
  log_params "Joining networks from environment:" $ZEROTIER_JOIN_NETWORKS
  for i in $ZEROTIER_JOIN_NETWORKS
  do
    log_detail_params "Configuring join:" "$i"
    touch "/var/lib/zerotier-one/networks.d/${i}.conf"
  done
fi

if [ -d "/var/lib/zerotier-one/moons.d" ]; then # check if the moons conf has generated
  moon_id=$(cat /var/lib/zerotier-one/identity.public | cut -d ':' -f1)
  echo -e "Your ZeroTier moon id is \033[0;31m$moon_id\033[0m, you could orbit moon using \033[0;31m\"zerotier-cli orbit $moon_id $moon_id\"\033[0m"
  /usr/sbin/zerotier-one
else
  nohup /usr/sbin/zerotier-one >/dev/null 2>&1 &
  # Waiting for identity generation...'
  while [ ! -f /var/lib/zerotier-one/identity.secret ]; do
    sleep 1
  done
  /usr/sbin/zerotier-idtool initmoon /var/lib/zerotier-one/identity.public >>/var/lib/zerotier-one/moon.json
  sed -i 's/"stableEndpoints": \[\]/"stableEndpoints": ['$stableEndpointsForSed']/g' /var/lib/zerotier-one/moon.json
  /usr/sbin/zerotier-idtool genmoon /var/lib/zerotier-one/moon.json >/dev/null
  mkdir /var/lib/zerotier-one/moons.d
  mv *.moon /var/lib/zerotier-one/moons.d/
  pkill zerotier-one
  moon_id=$(cat /var/lib/zerotier-one/moon.json | grep \"id\" | cut -d '"' -f4)
  echo -e "Your ZeroTier moon id is \033[0;31m$moon_id\033[0m, you could orbit moon using \033[0;31m\"zerotier-cli orbit $moon_id $moon_id\"\033[0m"
  exec /usr/sbin/zerotier-one
fi
