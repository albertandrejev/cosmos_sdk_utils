#!/bin/bash

PATH_TO_SERVICE=$1
VALIDATOR_ADDRESS=$2
HEIGHT=$3
NODE=${4:-"http://localhost:26657"}
LIMIT=${5:-"100000"}

source ./utils.sh

mkdir -p $WORKING_DIR

echo "Collecting data..."

get_validator_delegators $PATH_TO_SERVICE $VALIDATOR_ADDRESS $HEIGHT $NODE $LIMIT

echo "${DELEGATORS}" > "${WORKING_DIR}/delegators.json"
