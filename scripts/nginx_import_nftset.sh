#!/bin/sh

ARGS="-h 127.0.0.5 -p 6333 -n 0"

valkey-cli $ARGS keys \* | cut -d ' ' -f2 | grep -v white | while read i; do
        # nft add set ip raw chain_DENY {type ipv4_addr \; size 10000\;}
        nft add element ip raw chain_DENY { $i }
        [ $? -eq 0 ] && echo "added $i"
done

