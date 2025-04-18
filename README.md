# DLT-based Service Federation — DESIRE6G Project

This repository contains the source code for the **DLT-based Federation** module, part of the **Service Management and Orchestration (SMO)** component developed under the [DESIRE6G](https://desire6g.eu/) project.

**Author:** Adam Zahir Rodriguez  

---

## Installation

1. Clone the repository:
```bash
git clone git@github.com:adamzr2000/dlt-federation-demo.git
cd dlt-federation-demo
```

2. Build Docker Images:
Navigate to the [docker-images](./docker-images) directory and run the `./build.sh` scripts for each image:

- `dlt-node`: [Go-Ethereum (Geth)](https://geth.ethereum.org/docs) client for creating private Ethereum-based blockchain networks. (detailed info [here](./docker-images/dlt-node/)). ✅ Available 

- `truffle`: Development environment for compiling, testing, and deploying the [Federation Smart Contract](./smart-contracts/contracts/Federation.sol) using the [Truffle](https://archive.trufflesuite.com/docs/truffle/) framework.. (detailed info [here](./docker-images/truffle/)). ✅ Available 

- `dlt-federation-api`: REST API built with [FastAPI](https://github.com/fastapi/fastapi) and [Web3.py](https://web3py.readthedocs.io/en/stable/) that exposes endpoints for interacting with the deployed `Federation Smart Contract`. (detailed info [here](./docker-images/dlt-federation-api/)). ✅ Available 

- `eth-netstats`: Web dashboard for monitoring Ethereum network. (detailed info [here](./docker-images/eth-netstats/)). ✅ Available 

---

## Blockchain Network Setup

Create a blockchain network using `dlt-node` container images on `Domain1` (bootnode), `Domain2`, and `Domain3`. 

⚠️ Before running the setup scripts, update IP addresses in:
- [node1.env](./config/dlt/node1.env)
- [node2.env](./config/dlt/node2.env)
- [node3.env](./config/dlt/node3.env)


1. Initialize Network (Domain1):

```bash
cd dlt-network
./start_dlt_network.sh
```

2. Join Network (Domain2)

```bash
cd dlt-network
./join_dlt_network.sh --node node2 --validators 3
```

3. Join Network (Domain3)

```bash
cd dlt-network
./join_dlt_network.sh --node node3 --validators 3
```

4. Verify Node Connectivity

```bash
# Domain1
./get_peer_nodes.sh --node node1

# Domain2  
./get_peer_nodes.sh --node node2

# Domain3  
./get_peer_nodes.sh --node node3
```

Each command should show `2 peers`.

📊 Network Dashboard: [http://10.5.15.55:3000](http://10.5.15.55:3000)

5. Stop Network (Domain1):

```bash
./stop_dlt_network.sh
```

---

## Usage

1. Deploy the `Federation Smart Contract`

```bash
./deploy_smart_contract.sh --node-ip 10.5.15.55 --ws-port 3334 
```

2. Run the `dlt-federation-api` in each domain

Use the appropriate environment file:
- [domain1.env](./config/federation/domain1.env)
- [domain2.env](./config/federation/domain2.env)
- [domain3.env](./config/federation/domain3.env)

```bash
# Domain1
./start_dlt_service.sh --env-file config/federation/domain1.env --port 8080

# Domain2
./start_dlt_service.sh --env-file config/federation/domain2.env --port 8080

# Domain3
./start_dlt_service.sh --env-file config/federation/domain2.env --port 8080
```

📚 FastAPI Docs: [http://localhost:8080/docs](http://localhost:8080/docs)

3. Register each domain in the `Federation Smart Contract`:

```bash 
# Domain1
curl -X POST http://localhost:8080/register_domain \
  -H 'Content-Type: application/json' \
  -d '{"name": "Domain1"}' | jq

# Domain2
curl -X POST http://localhost:8080/register_domain \
  -H 'Content-Type: application/json' \
  -d '{"name": "Domain2"}' | jq

# Domain3
curl -X POST http://localhost:8080/register_domain \
  -H 'Content-Type: application/json' \
  -d '{"name": "Domain3"}' | jq
```

3. Simulate provider federation process (Domain2 & Domain3)

> Note: This simulates the provider-side service federation process, including bid placement, waiting for selection, and service deployment.

```bash
# Domain2
curl -X POST 'http://localhost:8080/simulate_provider_federation_process' \
-H 'Content-Type: application/json' \
-d '{
   "export_to_csv": false, 
   "service_price": 3,
   "offered_service": "detnet_transport",
   "topology_db": "http://10.5.99.5:9999/topology",
   "ns_id": "federation-net"
}' | jq
```

```bash
# Domain3
curl -X POST 'http://localhost:8080/simulate_provider_federation_process' \
-H 'Content-Type: application/json' \
-d '{
   "export_to_csv": false, 
   "service_price": 5,
   "offered_service": "k8s_deployment",
   "topology_db": "http://10.5.99.6:9999/topology",
   "ns_id": "federation-net"
}' | jq
```

4. Trigger federation from consumer (Domain1)

> Note: This simulates the consumer-side service federation process, including service announcement, bid evaluation, and provider selection.

```bash
curl -X POST 'http://localhost:8080/simulate_consumer_federation_process' \
-H 'Content-Type: application/json' \
-d '{
   "export_to_csv": true, 
   "csv_path": "/experiments/domain1",
   "service_type": "k8s_deployment",
   "compute_cpus": 2,
   "compute_ram_gb": 4,
   "service_catalog_db": "http://10.5.15.55:9999/catalog",
   "topology_db": "http://10.5.15.55:9999/topology",
   "nsd_id": "provider-ros-app.yaml",
   "ns_id": "federation-net"
}' | jq
```

```bash
curl -X POST 'http://localhost:8080/simulate_consumer_federation_process' \
-H 'Content-Type: application/json' \
-d '{
   "export_to_csv": false, 
   "service_type": "detnet_transport",
   "bandwidth_gbps": 0.1,
   "rtt_latency_ms": 20,
   "topology_db": "http://10.5.15.55:9999/topology",
   "ns_id": "federation-net"
}' | jq
```

---

## DLT Federation API Endpoints

### Web3 Info
Returns `web3_info` details; otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8080/web3_info' | jq
```

---

### Transaction Receipt
Returns `tx-receipt` details for a specified `tx_hash`; otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8080/tx_receipt?tx_hash=<tx_hash>' | jq
```

---

### Register Domain
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8080/register_domain' \
-H 'Content-Type: application/json' \
-d '{
   "name": "<domain_name>"
}' | jq
```

---

### Unregister Domain
Returns the `tx_hash`; otherwise returns an error message.

```sh
curl -X DELETE 'http://localhost:8080/unregister_domain' | jq
```

---

### Create Service Announcement
Returns the `tx_hash` and `service_id` for federation; otherwise returns an error message.
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

---

### Check Service Announcements
Returns `announcements` details; otherwise, returns an error message.
```sh
curl -X GET 'http://localhost:8080/service_announcements' | jq
```

---

### Place Bid
Returns the `tx_hash`; otherwise returns an error message.
```sh
curl -X POST 'http://localhost:8080/place_bid' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>", 
   "service_price": 5
}' | jq
```

---

### Check Bids
Returns `bids` details; otherwise returns an error message.
```sh
curl -X GET 'http://localhost:8080/bids?service_id=<id>' | jq
```

---

### Choose Provider
Returns the `tx_hash`; otherwise returns an error message.
```sh
curl -X POST 'http://localhost:8080/choose_provider' \
-H 'Content-Type: application/json' \
-d '{
   "bid_index": 0, 
   "service_id": "<id>"
}' | jq
``` 

---

### Send Endpoint Info
Returns the `tx_hash`; otherwise returns an error message.
```sh
curl -X POST 'http://localhost:8080/send_endpoint_info' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>", 
   "service_catalog_db": "http://10.5.15.55:5000/catalog",
   "topology_db": "http://10.5.15.55:5000/topology",
   "nsd_id": "ros-app.yaml",
   "ns_id": "ros-service-consumer"
}' | jq
``` 

---

### Check if a winner has been chosen
Returns the `winner`, which can be `yes`, or `no`; otherwise, returns an error message.
```sh
curl -X GET 'http://localhost:8080/winner_status?service_id=<id>' | jq
```

---

### Check if the calling provider is the winner
Returns the `is_winner`, which can be `yes`, or `no`; otherwise, returns an error message.
```sh
curl -X GET 'http://localhost:8080/is_winner?service_id=<id>' | jq
```

---

### Send Endpoint Info
Returns the `tx_hash`; otherwise returns an error message.
```sh
curl -X POST 'http://localhost:8080/send_endpoint_info' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>", 
   "topology_db": "http://10.5.15.56:5000/topology",
   "ns_id": "ros-service-provider"
}' | jq
``` 

---

### Confirm Service Deployment
Returns the `tx_hash`; otherwise returns an error message.
```sh
curl -X POST 'http://localhost:8080/service_deployed' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>",
   "federated_host": "10.0.0.10"
}' | jq
```

---

### Check Service State
Returns the `state` of the federated service, which can be `open`,`closed`, or `deployed`; otherwise, returns an error message.
```sh
curl -X GET 'http://localhost:8080/service_state?service_id=<id>' | jq
```

---

### Check Deployed Info
Returns the `federated_host` (IP address of the deployed service) along with either `endpoint_consumer` or `endpoint_provider` details; otherwise, returns an error message.
```sh
curl -X GET 'http://localhost:8080/service_info?service_id=<id>' | jq
```
