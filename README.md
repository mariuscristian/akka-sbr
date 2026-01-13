# Akka Cluster SBR Testing with Toxiproxy

This project demonstrates an Akka Cluster (4 nodes) with Split Brain Resolver (SBR) configured (`keep-oldest`), using Toxiproxy to simulate network partitions.

## Prerequisites
- Java 21+
- Maven
- Docker & Docker Compose

## Setup & Run

1.  **Build the application**:
    ```bash
    mvn clean package
    ```

2.  **Start the environment**:
    ```bash
    docker-compose up -d --build
    ```

3.  **Configure Toxiproxy** (Required for nodes to communicate):
    ```bash
    ./scripts/setup-toxiproxy.sh
    ```
    *Note: The nodes are configured to connect via Toxiproxy. Until this script is run, they will be unable to form a cluster.*

4.  **Verify Cluster Formation**:
    Check the cluster status via dashboard http://localhost:8080

## Simulating Failures

Use the `simulate-partition.sh` script to inject failures.

### Available Commands:
*   **Break a link**: Cut off link between two nodes.
    ```bash
    ./scripts/simulate-partition.sh block-link node-1 node-2
    ```

*   **Heal a link**: Heal link between two nodes.
    ```bash
    ./scripts/simulate-partition.sh heal-link node-1 node-2
    ```

*   **Isolate a Node**: Completely cuts off network traffic to/from a node.
    ```bash
    ./scripts/simulate-partition.sh isolate-node node-1
    ```
    *Expectation*: Node 1 becomes unreachable. SBR `keep-oldest` will down it if it's not the oldest partition, or down the others.*

*   **Heal a Node**: Restores traffic.
    ```bash
    ./scripts/simulate-partition.sh heal-node node-1
    ```

*   **Heal All**: Resets all proxies to working state.
    ```bash
    ./scripts/simulate-partition.sh heal-all
    ```

## Auditing

Check the logs to see SBR decisions and cluster events:
```bash
docker-compose logs -f node-1 node-2 node-3 node-4
```
Look for `MemberDowned`, `MemberRemoved`, and `LeaderChanged`.

## Configuration
- **Akka Config**: `src/main/resources/application.conf`
- **SBR Strategy**: `keep-oldest`, `down-if-alone = off`


## Reproduce split brain

1. Isolate node 1 by cutting off incoming links with slight delay (trigger indirectly connected node reaction):
```bash
./scripts/simulate-partition.sh block-link node-2 node-1; sleep 4; ./scripts/simulate-partition.sh block-link node-3 node-1; ./scripts/simulate-partition.sh block-link node-4 node-1;
```

2. Observe cluster: node-1 leader in own cluster, node-3 leader in cluster with node-4. Logs of node-2 show:
```
07:30:41.561 [sbr-demo-akka.actor.default-dispatcher-17] WARN  akka.cluster.sbr.SplitBrainResolver - SBR took decision DownIndirectlyConnected and is downing [akka://sbr-demo@toxiproxy:12551, akka://sbr-demo@toxiproxy:12552] including myself,, [1] unreachable of [4] members, indirectly connected [UniqueAddress(akka://sbr-demo@toxiproxy:12551,8624567562550974296), UniqueAddress(akka://sbr-demo@toxiproxy:12552,-1524992868029554616)], all members in DC [Member(akka://sbr-demo@toxiproxy:12551, Up), Member(akka://sbr-demo@toxiproxy:12552, Up), Member(akka://sbr-demo@toxiproxy:12553, Up), Member(akka://sbr-demo@toxiproxy:12554, Up)], full reachability status: [akka://sbr-demo@toxiproxy:12551 -> akka://sbr-demo@toxiproxy:12552: Unreachable [Unreachable] (1), akka://sbr-demo@toxiproxy:12552 -> akka://sbr-demo@toxiproxy:12551: Unreachable [Unreachable] (1)]
```

3. Heal links
```bash
./scripts/simulate-partition.sh heal-link node-2 node-1; ./scripts/simulate-partition.sh heal-link node-3 node-1; ./scripts/simulate-partition.sh heal-link node-4 node-1;
```