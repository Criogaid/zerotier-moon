#!/bin/bash

if ! zerotier-cli status | grep -q ONLINE; then
  echo "Zerotier is not online."
  exit 1
fi

echo "Zerotier is online."

