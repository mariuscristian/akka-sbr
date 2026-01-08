#!/bin/bash
# scripts/simulate-partition.sh

TOXIPROXY_URL="http://localhost:8474"

command=$1
param=$2

usage() {
  echo "Usage: $0 {isolate-node|heal-node|block-link|heal-link|partition-2-2|heal-all} [node-name]"
  echo "  isolate-node <node-name> : completely cuts off <node-name> from others"
  echo "  heal-node <node-name>    : restores connection for <node-name>"
  echo "  block-link <from-node> <to-node> : blocks traffic from <from-node> to <to-node>"
  echo "  heal-link <from-node> <to-node>  : restores traffic from <from-node> to <to-node>"
  echo "  partition-2-2            : partitions [node-1, node-2] vs [node-3, node-4]"
  echo "  heal-all                 : removes all toxics and iptables rules"
}

get_node_ip() {
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "sbr-$1-1"
}

get_proxy_port() {
  local node=$1
  case $node in
    node-1) echo 12551 ;;
    node-2) echo 12552 ;;
    node-3) echo 12553 ;;
    node-4) echo 12554 ;;
    *) echo "" ;;
  esac
}

block_link() {
  local from=$1
  local to=$2
  local ip=$(get_node_ip $from)
  local port=$(get_proxy_port $to)
  
  if [ -z "$ip" ] || [ -z "$port" ]; then
    echo "Error resolving IP or Port for $from -> $to"
    exit 1
  fi

  echo "Blocking $from ($ip) -> $to (ProxyPort $port)"
  # We run iptables in the toxiproxy container
  docker-compose exec -T toxiproxy iptables -I INPUT -s $ip -p tcp --dport $port -j DROP
}

heal_link() {
  local from=$1
  local to=$2
  local ip=$(get_node_ip $from)
  local port=$(get_proxy_port $to)

  echo "Healing $from -> $to"
  # Try deleting the rule. 2>&1 to suppress error if rule doesn't exist
  docker-compose exec -T toxiproxy iptables -D INPUT -s $ip -p tcp --dport $port -j DROP 2>/dev/null || true
}

add_toxic_down() {
  local proxy=$1
  echo "Cutting connection for proxy $proxy (downstream)"
  # "timeout" toxic:
  curl -s -X POST -d '{"type": "timeout", "attributes": {"timeout": 0}}' $TOXIPROXY_URL/proxies/$proxy/toxics
}

disable_proxy() {
    local proxy=$1
    echo "Disabling proxy $proxy"
    curl -s -X POST -d '{"enabled": false}' $TOXIPROXY_URL/proxies/$proxy
}

enable_proxy() {
    local proxy=$1
    echo "Enabling proxy $proxy"
    curl -s -X POST -d '{"enabled": true}' $TOXIPROXY_URL/proxies/$proxy
}


case "$command" in
  isolate-node)
    if [ -z "$param" ]; then usage; exit 1; fi
    disable_proxy "$param"
    ;;
  heal-node)
    if [ -z "$param" ]; then usage; exit 1; fi
    enable_proxy "$param"
    ;;
  block-link)
    if [ -z "$2" ] || [ -z "$3" ]; then 
       echo "Usage: $0 block-link <from> <to>"
       usage
       exit 1
    fi
    block_link "$2" "$3"
    ;;
  heal-link)
    if [ -z "$2" ] || [ -z "$3" ]; then 
       echo "Usage: $0 heal-link <from> <to>"
       usage
       exit 1
    fi
    heal_link "$2" "$3"
    ;;
  heal-all)
    echo "Healing all..."
    enable_proxy "node-1"
    enable_proxy "node-2"
    enable_proxy "node-3"
    enable_proxy "node-4"
    # Also remove any toxics if we added them
    curl -s -X DELETE $TOXIPROXY_URL/proxies/node-1/toxics > /dev/null 2>&1
    curl -s -X DELETE $TOXIPROXY_URL/proxies/node-2/toxics > /dev/null 2>&1
    curl -s -X DELETE $TOXIPROXY_URL/proxies/node-3/toxics > /dev/null 2>&1
    curl -s -X DELETE $TOXIPROXY_URL/proxies/node-4/toxics > /dev/null 2>&1
    
    # Flush iptables
    docker-compose exec -T toxiproxy iptables -F
    ;;
  *)
    usage
    exit 1
    ;;
esac
