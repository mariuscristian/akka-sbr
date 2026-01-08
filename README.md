# Akka Cluster SBR Testing with Toxiproxy

This project demonstrates an Akka Cluster (4 nodes) with Split Brain Resolver (SBR) configured (`keep-oldest`), using Toxiproxy to simulate network partitions.

## Prerequisites
- Java 11+
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
    Check the cluster status via the Akka Management HTTP endpoint (exposed on Node 1):
    ```bash
    curl http://localhost:8558/cluster/members
    ```
    You should see 4 members with status `Up`.

## Simulating Failures

Use the `simulate-partition.sh` script to inject failures.

### Available Commands:

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
