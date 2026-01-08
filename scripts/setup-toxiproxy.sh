#!/bin/bash
# scripts/setup-toxiproxy.sh

# Function to create a proxy
create_proxy() {
  local name=$1
  local listen_port=$2
  local upstream_host=$3
  local upstream_port=$4

  echo "Creating proxy $name listening on $listen_port -> $upstream_host:$upstream_port"
  curl -s -X POST -d "{\"name\": \"$name\", \"listen\": \"0.0.0.0:$listen_port\", \"upstream\": \"$upstream_host:$upstream_port\", \"enabled\": true}" http://localhost:8474/proxies
}

echo "Waiting for Toxiproxy API..."
until curl -s http://localhost:8474/version > /dev/null; do
  sleep 1
done

# Create proxies for each node
# Node 1
create_proxy "node-1" 12551 "node-1" 25520
# Node 2
create_proxy "node-2" 12552 "node-2" 25520
# Node 3
create_proxy "node-3" 12553 "node-3" 25520
# Node 4
create_proxy "node-4" 12554 "node-4" 25520

echo "All proxies created."
