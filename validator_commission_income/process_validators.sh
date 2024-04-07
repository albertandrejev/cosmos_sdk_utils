#!/bin/bash

cd $(dirname "$0")

CONFIG_DIR=$1

source ./utils.sh

echo "Starting new commission calculation: "`date`" ========================="

while read -r address; do
    echo "Processing address $address..."
    source ./commission_cashback.sh \
        $CONFIG_DIR \
        $address \
        "${DATA_DIR}${address}.json"  
done < $ADDRESSES_FILE