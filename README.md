# EVPN VXLAN Topology

```text
# ─────────────────────────────────────────────────────────────────────────────
#  FABRIC SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
#
#  Topology:   2 spines  ·  2x MLAG leaf pairs  ·  4 hosts (LACP bonded)
#  Underlay:   eBGP over P2P /31 links
#  Overlay:    EVPN/VXLAN  ·  anycast VTEP per MLAG pair
#  Isolation:  per-VLAN VRF (no inter-VLAN routing)
#
#  AS assignments:
#    spine1 + spine2   →  AS 65001  (eBGP route-relay for EVPN)
#    leaf1  + leaf2    →  AS 65002  (MLAG pair A)
#    leaf3  + leaf4    →  AS 65003  (MLAG pair B)
#
#  Loopbacks:
#    spine1            →  Lo0: 10.0.0.1/32
#    spine2            →  Lo0: 10.0.0.2/32
#    leaf1             →  Lo0: 10.0.0.11/32  Lo1 (VTEP): 10.0.0.101/32
#    leaf2             →  Lo0: 10.0.0.12/32  Lo1 (VTEP): 10.0.0.101/32
#    leaf3             →  Lo0: 10.0.0.13/32  Lo1 (VTEP): 10.0.0.102/32
#    leaf4             →  Lo0: 10.0.0.14/32  Lo1 (VTEP): 10.0.0.102/32
#
#  P2P subnets (spine1):
#    spine1:eth1 ↔ leaf1:eth1   →  10.1.1.0/31  (.0=spine1 .1=leaf1)
#    spine1:eth2 ↔ leaf2:eth1   →  10.1.1.2/31  (.2=spine1 .3=leaf2)
#    spine1:eth3 ↔ leaf3:eth1   →  10.1.1.4/31  (.4=spine1 .5=leaf3)
#    spine1:eth4 ↔ leaf4:eth1   →  10.1.1.6/31  (.6=spine1 .7=leaf4)
#
#  P2P subnets (spine2):
#    spine2:eth1 ↔ leaf1:eth2   →  10.1.2.0/31  (.0=spine2 .1=leaf1)
#    spine2:eth2 ↔ leaf2:eth2   →  10.1.2.2/31  (.2=spine2 .3=leaf2)
#    spine2:eth3 ↔ leaf3:eth2   →  10.1.2.4/31  (.4=spine2 .5=leaf3)
#    spine2:eth4 ↔ leaf4:eth2   →  10.1.2.6/31  (.6=spine2 .7=leaf4)
#
#  MLAG peer-link SVIs:
#    leaf1 Vlan4094              →  169.254.0.1/30
#    leaf2 Vlan4094              →  169.254.0.2/30
#    leaf3 Vlan4094              →  169.254.1.1/30
#    leaf4 Vlan4094              →  169.254.1.2/30
#
#  MLAG port-channels (same MLAG ID on both peers):
#    Po1   →  MLAG peer-link  (eth3+eth4 on both leaves)
#    Po10  →  hostA/hostC     (MLAG ID 10, VLAN 100/300)
#    Po20  →  hostB/hostD     (MLAG ID 20, VLAN 200/400)
#
#  VNI mapping:
#    VLAN 100  →  L2VNI 10100  VRF VLAN100  L3VNI 50100
#    VLAN 200  →  L2VNI 10200  VRF VLAN200  L3VNI 50200
#
#  Anycast gateway (ip virtual-router mac-address 00:1c:73:00:00:01):
#    VLAN 100  →  10.100.1.1/24
#    VLAN 200  →  10.200.1.1/24
```
