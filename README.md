# DLT-based Service Federation

## Installation

1. Clone the repository:
```bash
git clone git@github.com:adamzr2000/dlt-federation-demo.git
```

2. Build Docker Images:
Navigate to the [docker-images](./docker-images) directory and run the `./build.sh` scripts for each image:

- `dlt-node`: Based on [Go-Ethereum (Geth)](https://geth.ethereum.org/docs) software, serving as nodes within the peer-to-peer blockchain network. (detailed info [here](./docker-images/dlt-node/)). ![#00FF00](https://via.placeholder.com/15/00ff00/000000?text=+) Available

- `truffle`: Development framework for Ethereum-based blockchain applications. It provides a suite of tools that allows developers to write, test, and deploy smart contracts. (detailed info [here](./docker-images/truffle/)). ![#00FF00](https://via.placeholder.com/15/00ff00/000000?text=+) Available

- `dlt-federation-api`:

## Blockchain Network Setup

Create a blockchain network using `dlt-node` containers.  The network will comprise three nodes, corresponding to `AD1`, `AD2`, and `AD3`, respectively. AD1 will serve as the bootnode to connect all nodes.

1. Initialize the network:

In `AD1`, go to the [dlt-network](./dlt-network) directory and start the network setup:

> Note: Before running the script, update the IP addresses in [node1.env](./config/dlt/node1.env), [node2.env](./config/dlt/node2.env) and [node3.env](./config/dlt/node3.env). Replace `IP_NODE_1` with the IP address of your `AD1`, `IP_NODE_2` with the IP address of your `AD2`, and `IP_NODE_3` with the IP address of your `AD3`.

```bash
cd dlt-network
./start_dlt_network.sh
```

2. Join the network from a second node

In `AD2`, go to the [dlt-network](./dlt-network) directory and run:

```bash
cd dlt-network
./join_dlt_network.sh --node node2 --validators 3
```

3. Join the network from a second node

In `AD3`, go to the [dlt-network](./dlt-network) directory and run:

```bash
cd dlt-network
./join_dlt_network.sh --node node3 --validators 3
```


3. Verify node association

Use the following commands to confirm both nodes are connected:

```bash
# AD1
./get_peer_nodes.sh --node node1

# AD2  
./get_peer_nodes.sh --node node2

# AD3  
./get_peer_nodes.sh --node node2
```

Each command should show `2 peers`.

Access the `grafana` dashboard for additional information at [http://localhost:3000](http://localhost:3000)

> Note: The username is `desire6g` and the password `desire6g2024;`

5. Stop the network:

In `AD1`, when needed, use the following command to stop the network:

```bash
./stop_dlt_network.sh
```

## Usage

1. Deploy the Federation SC to the blockchain Network:

```bash
./deploy_smart_contract.sh --node-ip 10.5.15.55 --ws-port 3334 
```

2. Run the DLT Service Federation module on each AD, specifying the domain parameters in the [federation](./dlt-network/) directory. Use at least the following files:

   - [consumer1.env](./config/federation/consumer1.env)
   - [provider1.env](./config/federation/provider1.env)

```bash
# AD1
./start_dlt_service.sh --env-file config/federation/consumer1.env --port 8080

# AD2
./start_dlt_service.sh --env-file config/federation/provider1.env --port 8080
```

For more details on federation functions, refer to the FastAPI documentation at [http://localhost:8080/docs](http://localhost:8080/docs)

3. Register each AD in the Federation SC:

```bash 
curl -X POST 'http://localhost:8080/register_domain' \
-H 'Content-Type: application/json' \
-d '{
   "name": "<domain_name>"
}'
```

3. Start listening for federation events on the provider ADs:

> Note: This simulates the provider-side service federation process, including bid placement, 
waiting for selection, and service deployment.

```bash
curl -X POST 'http://localhost:8080/simulate_provider_federation_process' \
-H 'Content-Type: application/json' \
-d '{
   "vim": "<docker/kubernetes>", 
   "export_to_csv": <true/false>, 
   "service_price": <federation_price_offering (e.g., 10)>,
   "endpoint_provider": "ip_address=10.5.99.2;vxlan_id=200;vxlan_port=4789;federation_net=10.0.0.0/16"
}'
```

4. Trigger a federation request from the consumer AD:

> Note: This simulates the consumer-side service federation process, including service announcement, bid evaluation, and provider selection.

```bash
curl -X POST 'http://localhost:8080/simulate_consumer_federation_process' \
-H 'Content-Type: application/json' \
-d '{
   "vim": "<docker/kubernetes>", 
   "export_to_csv": <true/false>, 
   "service_providers": <federation_offers_to_wait (e.g., 1)>,
   "requirements": "service=alpine;replicas=1", 
   "endpoint_consumer": "ip_address=10.5.99.1;vxlan_id=200;vxlan_port=4789;federation_net=10.0.0.0/16"
}'
```

## DLT Federation API Endpoints

### Web3 Info
Returns `web3_info` details; otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8080/web3_info' | jq
```

### Transaction Receipt
Returns `tx-receipt` details for a specified `tx_hash`; otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8080/tx_receipt?tx_hash=<tx_hash>' | jq
```

### Register Domain
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/register_domain' \
-H 'Content-Type: application/json' \
-d '{
   "name": "<domain_name>"
}' | jq
```

### Unregister Domain
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X DELETE 'http://localhost:8080/unregister_domain' | jq
```

### Create Service Announcement
Returns the `tx_hash` and `service_id` for federation; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/create_service_announcement' \
-H 'Content-Type: application/json' \
-d '{
   "service_type": "K8s App Deployment"
}' | jq
```

```sh
curl -X POST 'http://localhost:8080/create_service_announcement' \
-H 'Content-Type: application/json' \
-d '{
   "service_type": "K8s App Deployment",
   "bandwidth_gbps": 0.1,
   "rtt_latency_ms": 20,
   "compute_cpus": 2,
   "compute_ram_gb": 4
}' | jq
```

### Check Service Announcements
Returns `announcements` details; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8080/service_announcements' | jq
```

### Place Bid
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/place_bid' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>", 
   "service_price": <federation_price_offering (e.g., 10)>
}' | jq
```

### Check Bids
Returns `bids` details; otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8080/bids?service_id=<id>' | jq
```

### Choose Provider
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/choose_provider' \
-H 'Content-Type: application/json' \
-d '{
   "bid_index": <index>, 
   "service_id": "<id>"
}' | jq
``` 

### Send Endpoint Info
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/send_endpoint_info' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>", 
   "service_catalog_db": "<service_catalog_url>",
   "topology_db": "<topology_url>",
   "nsd_id": "<nsd_id>",
   "ns_id": "<ns_id>"
}' | jq
``` 

### Check if a winner has been chosen
Returns the `winner`, which can be `yes`, or `no`; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8080/winner_status?service_id=<id>' | jq
```

### Check if the calling provider is the winner
Returns the `is_winner`, which can be `yes`, or `no`; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8080/is_winner?service_id=<id>' | jq
```

### Send Endpoint Info
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/send_endpoint_info' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>", 
   "topology_db": "<topology_url>",
   "ns_id": "<ns_id>"
}' | jq
``` 

### Confirm Service Deployment
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/service_deployed' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>",
   "federated_host": "<federated_host_ip>"
}' | jq
```

### Check Service State
Returns the `state` of the federated service, which can be `open`,`closed`, or `deployed`; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8080/service_state?service_id=<id>' | jq
```

### Check Deployed Info
Returns the `federated_host` (IP address of the deployed service) along with either `endpoint_consumer` or `endpoint_provider` details; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8080/service_info?service_id=<id>' | jq
```