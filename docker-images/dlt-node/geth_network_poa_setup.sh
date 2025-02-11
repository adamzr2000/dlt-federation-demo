#!/bin/bash

# Function to prompt the user for input and validate it
prompt_and_validate_input() {
  local prompt_message="$1"
  local variable_name="$2"
  local validation_pattern="$3"

  while true; do
    echo "$prompt_message"
    read -r $variable_name  # Remove the double quotes
    if [[ ! ${!variable_name} =~ $validation_pattern ]]; then  # Use ${!variable_name} to access the variable's value
      echo "Invalid input. Please try again."
    else
      break
    fi
  done
}

# Prompt for the number of geth nodes (>0 and <=50)
prompt_and_validate_input "Please enter the number of geth nodes for the network [>0]:" numNodes '^[1-9][0-9]*$'

# Prompt for period value (>=0 and <=60)
prompt_and_validate_input "Please enter the 'period' value (average time(s) interval for adding new blocks to the blockchain) [>=0]:" period '^[0-9]+$|^0$'

# Prompt for chainID value (>0)
prompt_and_validate_input "Please enter the 'chainID' value for genesis.json [>0]:" chainID '^[1-9][0-9]*$'

# Prompt for log saving option (y/n)
prompt_and_validate_input "Do you want to save logs in a .log file? (y/n):" saveLogs '^[ynYN]$'

echo "Number of nodes set to: $numNodes"
echo "Block period set to: $period seconds"
echo "Chain ID set to: $chainID"
echo "Save logs option: $saveLogs"

# Create the logs directory
mkdir -p logs

# Node creation and account generation
declare -a addresses
for (( i=1; i<=$numNodes; i++ ))
do
  mkdir "node$i"
  # Generate new account. Assumes password.txt is in the current directory.
  addr=$(geth --datadir node$i account new --password scripts/password.txt 2>&1 | grep "Public address of the key" | awk '{print $NF}')
  addresses+=("$addr")

  # Create node specific .env file
  node_env="node${i}.env"
  touch $node_env

  echo "# node$i config" >> $node_env
  echo "NODE_ID=\"node$i\"" >> $node_env
  echo "DATADIR=\"node$i\"" >> $node_env
  echo "ETHERBASE=$addr" >> $node_env
  echo "NODE_IP=127.0.0.1" >> $node_env
  echo "WS_PORT=$((3333 + $i))" >> $node_env
  echo "RPC_PORT=$((8550 + $i))" >> $node_env
  echo "ETH_PORT=$((30302 + $i))" >> $node_env
  echo "WS_URL=ws://\${NODE_IP}:\${WS_PORT}" >> $node_env
  echo "NETWORK_ID=$chainID" >> $node_env
  echo "SAVE_LOGS=$saveLogs" >> $node_env
  echo "" >> $node_env
  echo "# bootnode config" >> $node_env
  echo "BOOTNODE_IP=127.0.0.1" >> $node_env
  echo "BOOTNODE_PORT=30301" >> $node_env
  echo "BOOTNODE_KEY=\$(bootnode -writeaddress -nodekey ./bootnode/boot.key)" >> $node_env
  echo "BOOTNODE_URL=enode://\${BOOTNODE_KEY}@\${BOOTNODE_IP}:0?discport=\${BOOTNODE_PORT}" >> $node_env
  echo "" >> $node_env
  echo "# influxdb config" >> $node_env
  echo "INFLUXDB_USERNAME=\"admin\"" >> $node_env
  echo "INFLUXDB_PASSWORD=\"admin\"" >> $node_env
  echo "INFLUXDB_DB=\"geth\"" >> $node_env
  echo "INFLUXDB_IP=127.0.0.1" >> $node_env
  echo "INFLUXDB_PORT=8086" >> $node_env
  echo "" >> $node_env
  
  # Generate extraData and alloc parts for genesis.json
  extraData+="${addr#"0x"}"
  alloc+='"'${addr}'": { "balance": "100000000000000000000" },'

  echo "node$i created and configured."
done

# Call the Python script to decrypt private keys and write to env files
python3 scripts/private_key_decrypt.py

# Create multiple genesis files with incremental validators
for (( i=2; i<=$numNodes; i++ ))
do
  extraDataForGenesis="0x0000000000000000000000000000000000000000000000000000000000000000"
  for (( j=0; j<$i; j++ ))
  do
    extraDataForGenesis+="${addresses[j]#'0x'}"
  done
  extraDataForGenesis+="0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

  cat << EOF > "./genesis_${i}_validators.json"
{
  "config": {
    "chainId": $chainID,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "arrowGlacierBlock": 0,
    "grayGlacierBlock": 0,
    "clique": {
      "period": $period,
      "epoch": 30000
    }
  },
  "difficulty": "1",
  "gasLimit": "6721975",
  "extraData": "$extraDataForGenesis",
  "alloc": {
    ${alloc::-1}
  }
}
EOF

  echo "genesis_${i}_validators.json created and configured."
done

# Generate bootnode
mkdir -p bootnode && bootnode -genkey bootnode/boot.key

# Create bootnode specific .env file
bootnode_env="bootnode.env"
touch $bootnode_env

echo "# bootnode config" >> $bootnode_env
echo "BOOTNODE_IP=127.0.0.1" >> $bootnode_env
echo "BOOTNODE_PORT=30301" >> $bootnode_env
echo "BOOTNODE_KEY=\$(bootnode -writeaddress -nodekey ./bootnode/boot.key)" >> $bootnode_env
echo "BOOTNODE_URL=enode://\${BOOTNODE_KEY}@\${BOOTNODE_IP}:0?discport=\${BOOTNODE_PORT}" >> $bootnode_env
echo "" >> $bootnode_env
