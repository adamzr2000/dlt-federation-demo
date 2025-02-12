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

Create a blockchain network using `dlt-node` containers.  Initially, the network will comprise two nodes, corresponding to AD1 and AD2, respectively. AD1 will serve as the bootnode to connect both nodes.

1. Initialize the network:

In `AD1`, go to the [dlt-network](./dlt-network) directory and start the network setup:

> Note: Before running the script, update the IP addresses in [node1.env](./config/dlt/node1.env) and [node2.env](./config/dlt/node2.env). Replace `IP_NODE_1` with the IP address of your `AD1` and `IP_NODE_2` with the IP address of your `AD2`.

```bash
cd dlt-network
./start_dlt_network.sh
```

2. Join the network from a second node

In `AD2`, go to the [dlt-network](./dlt-network) directory and run:

```bash
cd dlt-network
./join_dlt_network.sh node2 2
```

3. Verify node association

Use the following commands to confirm both nodes are connected:

```bash
# AD1
 ./get_peer_nodes.sh node1

# AD2  
 ./get_peer_nodes.sh node2
```
Each command should show `1 peer`.

Access the `grafana` dashboard for additional information at [http://localhost:3000](http://localhost:3000)

> Note: The username is `desire6g` and the password `desire6g2024;`.

4. Add more nodes:

Use the [join_dlt_network.sh](./dlt-network/join_dlt_network.sh) script to add more nodes. 

> Note: The private network uses the [Clique (Proof-of-authority)](https://github.com/ethereum/EIPs/issues/225) consensus mechanism, where pre-elected signer nodes generate new blocks. Each new block is endorsed by the list of signers, and the last signer node is responsible for populating the new block with transactions. Block rewards are shared among all the signers. New nodes must be approved by at least `(NUMBER_OF_TOTAL_SIGNERS / 2) + 1` signers to join as "sealers." 

To add a new node as a sealer, run the [add_validator.sh](./dlt-network/add_validator.sh) script.

For example, to add a third node as a sealer in the blockchain, use the following commands:

```bash
# AD3
 ./join_dlt_network.sh node3 2

# AD1
./add_validator.sh node1 node3

# AD2 
./add_validator.sh node2 node3
```

Finally, check if the new node has been accepted as a sealer node with:

```bash
# AD3
./get_peer_nodes.sh node3 
```

5. Stop the network:

In `AD1`, when needed, use the following command to stop the network:

```bash
./stop_dlt_network.sh
```

## Usage

1. Deploy the Federation SC to the blockchain Network:

```bash
cd smart-contracts
./deploy.sh 
```

2. Run the DLT Service Federation module on each AD, specifying the domain parameters in the [federation](./dlt-network/) directory. Use at least the following files:

   - [consumer1.env](./config/federation/consumer1.env)
   - [provider1.env](./config/federation/provider1.env)

> Note: Before running the script, set `DOMAIN_FUNCTION` to your federation role (`consumer` or `provider`), update `INTERFACE_NAME` to your VM's network interface for the VXLAN tunnel, and set `SUDO_PASSWORD` to your machine's password for scripts requiring elevated privileges, such as network configuration and VXLAN setup.

```bash
# AD1
./start_app.sh --env-file config/federation/consumer1.env

# AD2
./start_app.sh --env-file config/federation/provider1.env
```

For more details on federation functions, refer to the FastAPI documentation at [http://localhost:8001/docs](http://localhost:8001/docs)

3. Register each AD in the Federation SC:

```bash 
curl -X POST 'http://localhost:8001/register_domain' \
-H 'Content-Type: application/json' \
-d '{
   "name": "<domain_name>"
}'
```

3. Start listening for federation events on the provider ADs:

> Note: This simulates the provider-side service federation process, including bid placement, 
waiting for selection, and service deployment.

```bash
curl -X POST 'http://localhost:8001/simulate_provider_federation_process' \
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
curl -X POST 'http://localhost:8001/simulate_consumer_federation_process' \
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
Returns `web3_info` details, otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8001/web3_info' | jq
```

### Transaction Receipt
Returns `tx-receipt` details for a specified `tx_hash`, otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8001/tx_receipt?tx_hash=<tx_hash>' | jq
```

### Register Domain
Returns the `tx_hash`, otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8001/register_domain' \
-H 'Content-Type: application/json' \
-d '{
   "name": "<domain_name>"
}' | jq
```

### Unregister Domain
Returns the `tx_hash`, otherwise returns an error message.

```sh
curl -X DELETE 'http://localhost:8001/unregister_domain' | jq
```

### Create Service Announcement
Returns the `tx_hash` and `service_id` for federation, otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8001/create_service_announcement' \
-H 'Content-Type: application/json' \
-d '{
   "endpoint_consumer": "ip_address=10.5.99.1;vxlan_id=200;vxlan_port=4789;federation_net=10.0.0.0/16",
   "service_type": "K8s App Deployment",
   "bandwidth_gbps": 0.1,
   "rtt_latency_ms": 20,
   "compute_cpus": 2,
   "compute_ram_gb": 4
}' | jq
```

### Check Service Announcements
Returns `announcements` details, otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8001/check_service_announcements' | jq
```

### Place Bid
Returns the `tx_hash`, otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8001/place_bid' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>", 
   "service_price": <federation_price_offering (e.g., 10)>,
   "endpoint_provider": "ip_address=10.5.99.2;vxlan_id=200;vxlan_port=4789;federation_net=10.0.0.0/16"
}'
```

### Check Bids
Returns `bids` details, otherwise returns an error message.

```sh
curl -X GET 'http://localhost:8001/check_bids?service_id=<id>' | jq
```

### Choose Provider
Returns the `tx_hash`, otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8001/choose_provider' \
-H 'Content-Type: application/json' \
-d '{
   "bid_index": <index>, 
   "service_id": "<id>"
}'
``` 

### Check if a winner has been chosen
Returns the `winner`, which can be `yes`, or `no`; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8001/winner_status?service_id=<id>' | jq
```

### Check if the calling provider is the winner
Returns the `is_winner`, which can be `yes`, or `no`; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8001/check_winner?service_id=<id>' | jq
```

### Confirm Service Deployment
Returns the `service_name`, otherwise returns an error message.

```sh
curl -X POST 'http://localhost:8001/service_deployed' \
-H 'Content-Type: application/json' \
-d '{
   "service_id": "<id>",
   "federated_host": "<federated_host_ip>"
}'
```

### Check Service State
Returns the `state` of the federated service, which can be `open`,`closed`, or `deployed`; otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8001/check_service_state?service_id=<id>' | jq
```

### Check Deployed Info
Returns the `service_endpoint` of the provider and `federated_host` (IP address of the deployed service); otherwise, returns an error message.

```sh
curl -X GET 'http://localhost:8001/check_deployed_info?service_id=<id>' | jq
```