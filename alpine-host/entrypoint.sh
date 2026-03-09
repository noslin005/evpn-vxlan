#!/bin/sh

##################################################
# Environment variable reference:
#
#   BOND      = <member1>:<member2>  (colon-separated, creates bond0 in 802.3ad mode)
#               e.g. BOND=eth1:eth2
#
#   BOND_MODE = 802.3ad (default) | active-backup | balance-rr |
#               balance-xor | broadcast | balance-tlb | balance-alb
#
#   BOND_MIIMON = 100 (default, ms)
#
#   ADDRESS   = <iface>:<cidr>[,<iface>:<cidr>,...]
#               If <iface> contains a dot, the VLAN is created automatically.
#               e.g. ADDRESS=eth1:10.0.0.1/24
#                    ADDRESS=eth1.100:10.0.0.1/24
#                    ADDRESS=bond0:10.0.0.1/24
#                    ADDRESS=bond0.100:10.0.0.1/24
#
#   ROUTES    = <prefix>:<nexthop>[,<prefix>:<nexthop>,...]
#               e.g. ROUTES=0.0.0.0/0:10.0.0.254
#
# Scenarios:
#   Static address on eth1:
#     ADDRESS=eth1:10.100.1.11/24
#
#   VLAN on eth1 with address:
#     ADDRESS=eth1.100:10.100.1.11/24
#
#   Bond eth1+eth2, address on bond:
#     BOND=eth1:eth2
#     ADDRESS=bond0:10.100.1.11/24
#
#   Bond eth1+eth2, VLAN on bond with address:
#     BOND=eth1:eth2
#     ADDRESS=bond0.100:10.100.1.11/24
##################################################

BOND_NAME='bond0'
BOND_MODE="${BOND_MODE:-802.3ad}"
BOND_MIIMON="${BOND_MIIMON:-100}"

echo "Bond members  : ${BOND:-none}"
echo "Bond mode     : ${BOND_MODE}"
echo "Bond miimon   : ${BOND_MIIMON}ms"
echo "Address(es)   : ${ADDRESS:-none}"
echo "Route(s)      : ${ROUTES:-none}"

#######################
# Re-run script as sudo
#######################

if [ "$(id -u)" != "0" ]; then
  exec sudo --preserve-env=BOND,BOND_MODE,BOND_MIIMON,ADDRESS,ROUTES "$0" "$@"
fi

##########################
# Wait for a physical interface to come up
##########################

wait_for_iface() {
  local iface="$1"
  local check
  check=$(cat /sys/class/net/${iface}/operstate 2>/dev/null)
  while [ "up" != "$check" ]; do
    echo "Waiting for $iface to come up..."
    sleep 1
    check=$(cat /sys/class/net/${iface}/operstate 2>/dev/null)
  done
  echo "$iface is up."
}

wait_for_iface eth1
wait_for_iface eth2

###############
# Enable LLDP
###############

lldpad -d
for i in $(ls /sys/class/net/ | grep 'eth\|ens\|eno'); do
  lldptool set-lldp -i "$i" adminStatus=rxtx
  lldptool -T -i "$i" -V sysName enableTx=yes
  lldptool -T -i "$i" -V portDesc enableTx=yes
  lldptool -T -i "$i" -V sysDesc enableTx=yes
done

################
# Bond setup
# BOND=eth1:eth2
################

if [ -n "$BOND" ]; then
  echo "Creating $BOND_NAME (mode=$BOND_MODE miimon=${BOND_MIIMON}ms)"
  ip link add name "$BOND_NAME" type bond mode "$BOND_MODE" miimon "$BOND_MIIMON"

  OLD_IFS="$IFS"
  IFS=':'
  for member in $BOND; do
    echo "  Adding $member -> $BOND_NAME"
    ip link set "$member" down
    ip link set "$member" master "$BOND_NAME"
  done
  IFS="$OLD_IFS"

  ip link set "$BOND_NAME" up
  echo "$BOND_NAME is up."
fi

################
# Address + auto-VLAN setup
# ADDRESS=bond0.100:10.100.1.11/24,bond0.200:10.100.2.11/24
#
# If the target interface contains a dot (e.g. bond0.100 or eth1.100),
# the VLAN sub-interface is created automatically before the address
# is assigned.
################

if [ -n "$ADDRESS" ]; then
  OLD_IFS="$IFS"
  IFS=','
  for entry in $ADDRESS; do
    entry=$(echo "$entry" | tr -d ' ')
    iface="${entry%%:*}"
    cidr="${entry##*:}"

    # Auto-create VLAN if interface name contains a dot
    case "$iface" in
    *.*)
      parent="${iface%%.*}"
      vlan_id="${iface##*.}"
      if ! ip link show "$iface" >/dev/null 2>&1; then
        echo "Creating VLAN $vlan_id on $parent -> $iface"
        ip link add link "$parent" name "$iface" type vlan id "$vlan_id"
        ip link set "$iface" up
      fi
      ;;
    esac

    echo "Assigning $cidr -> $iface"
    ip addr add "$cidr" dev "$iface"
  done
  IFS="$OLD_IFS"
fi

################
# Static routes
# ROUTES=0.0.0.0/0:10.0.0.254,192.168.0.0/16:10.0.0.1
################

if [ -n "$ROUTES" ]; then
  OLD_IFS="$IFS"
  IFS=','
  for entry in $ROUTES; do
    entry=$(echo "$entry" | tr -d ' ')
    prefix="${entry%%:*}"
    nexthop="${entry##*:}"
    if [[ $prefix == "0.0.0.0" ]]; then
      ip route del default
    fi
    echo "Adding route: $prefix via $nexthop"
    ip route add "$prefix" via "$nexthop"
  done
  IFS="$OLD_IFS"
fi

echo "------- Interface Link state -------"
ip -br link show
echo "------- Interface IP Address -------"
ip -br addr show
echo "------- Routes -------"
ip route show
echo "-------------------------------------"

#####################
# Sleeping loop
#####################

while sleep 3600; do :; done
