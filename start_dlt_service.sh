#!/bin/bash

# Default values
env_file="/app/config/federation/consumer1.env"
port="8080"
container_name="dlt-federation-api"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      env_file="$2"
      shift 2
      ;;
    --port)
      port="$2"
      shift 2
      ;;
    --container-name)
      container_name="$2"
      shift 2
      ;;      
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--env-file <path>] [--port <port>] [--container-name <container-name>]"
      exit 1
      ;;
  esac
done

echo "Running $container_name image with:"
echo " - Environment file: $env_file"
echo " - Exposed port: $port"

START_CMD="./run_server.sh"

docker run \
    -it \
    --name $container_name \
    --hostname $container_name \
    --rm \
    -p "$port":8000 \
    -v "$(pwd)/config":/app/config \
    -v "$(pwd)/smart-contracts":/app/smart-contracts \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/docker_functions.py":/app/docker_functions.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/kubernetes_functions.py":/app/kubernetes_functions.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/utility_functions.py":/app/utility_functions.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/main.py":/app/main.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/start_app.sh":/app/start_app.sh \
    -e FEDERATION_ENV_FILE="$env_file" \
    dlt-federation-api:latest \
    $START_CMD
