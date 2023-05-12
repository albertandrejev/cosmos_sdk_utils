#!/bin/bash

NETWORK_STATUS_OK="OK"
NETWORK_STATUS_NODE_NOT_REACHABLE="NOT_REACHABLE"
NETWORK_STATUS_BLOCK_IN_PAST="BLOCK_IN_PAST"

if [ -f "${CONFIG_DIR}/notification.sh" ]; then
    source ${CONFIG_DIR}/notification.sh
fi


network_up_and_synced () {
    local REST_NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" ${REST_NODE}/node_info)

    if (( $NODE_STATUS_CODE != 200 )); then
        echo "Node is not reachable. Exiting..." >&2
        echo $NETWORK_STATUS_NODE_NOT_REACHABLE
    fi

    local LATEST_BLOCK_TIME=$(curl -m 10 -s ${REST_NODE}/blocks/latest  | jq -r '.block.header.time')

    local CONTROL_TIME=$(date -d "-180 seconds")
    local BLOCK_TIME=$(date -d "${LATEST_BLOCK_TIME}")

    if [[ "$BLOCK_TIME" < "$CONTROL_TIME" ]];
    then
        echo "Block time is in past. Exiting..." >&2
        echo $NETWORK_STATUS_BLOCK_IN_PAST
    fi 

    echo $NETWORK_STATUS_OK
}

get_rest_url () {
    local REST_NODES_LIST_PATH=$1

    REST_NODES_LIST=$(cat $REST_NODES_LIST_PATH)
    REST_NODES_AMOUNT=$(echo "${REST_NODES_LIST}" | jq 'length - 1')

    RANDOM_NODE_IDX=$(shuf -i 0-${REST_NODES_AMOUNT} -n 1)

    REST_NODE=$(echo "${REST_NODES_LIST}" | jq -r ".[${RANDOM_NODE_IDX}]")

    echo $REST_NODE
}

notify () {
    local MESSAGE=$1 

    # Send notification message to notification service. "send_notification_message" should be implemented in the '../notification.sh'
    if [[ $(type -t send_notification_message) == function ]]; then
        send_notification_message "${MESSAGE}"
    fi    
}

notify_no_working_rest () {
    local CONFIG_DIR=$1

    local MESSAGE=$(cat <<-EOF
<b>[Notice] No working REST servers found</b>
Unable to find suitable REST server from list. Configuration directory: '<b>$CONFIG_DIR</b>'. Please examine <b>debug.log</b>.
EOF
)
    notify "${MESSAGE}"
}

