#!/bin/bash

echo 'Running dlt-federation-api image.'

docker run \
    -it \
    --name dlt-federation-api \
    --rm \
    --net host \
    -v "$(pwd)/config":/app/config \
    -v "$(pwd)/smart-contracts":/app/smart-contracts \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/docker_functions.py":/app/docker_functions.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/kubernetes_functions.py":/app/kubernetes_functions.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/utility_functions.py":/app/utility_functions.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/main.py":/app/main.py \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/start_app.sh":/app/start_app.sh \
    -v "$(pwd)/docker-images/dlt-federation-api/scripts/kubernetes_functions.py":/app/kubernetes_functions.py \
    -e FEDERATION_ENV_FILE="/app/config/federation/local-test.env" \
    dlt-federation-api:latest