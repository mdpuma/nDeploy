#!/bin/bash


if [ "$1" = "destroy" ]; then 
  handle=$(nft -a  list ruleset 2>/dev/null | grep 'comment "nginx1" ' | grep -oE "handle [0-9]+" | head -1)
  [ "$handle" != "" ] && nft delete rule ip raw PREROUTING $handle

  handle=$(nft -a  list ruleset 2>/dev/null | grep 'set chain_DENY {' | grep -oE "handle [0-9]+" | head -1)
  [ "$handle" != "" ] && nft delete set ip raw $handle
  echo "deleting nftables rules"
  exit
fi

echo "inserting nftables rule & creating set"
nft add chain ip raw PREROUTING \{ type filter hook prerouting priority raw \; policy accept \; \}
nft add set ip raw chain_DENY {type ipv4_addr \; size 10000\; timeout 5m\; }
nft insert rule ip raw PREROUTING tcp dport 443 ip saddr @chain_DENY counter drop comment nginx1
