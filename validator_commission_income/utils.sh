#!/bin/bash

NUMBER_RE='^[0-9]*([.][0-9]+)?$'
NO_COMMISSION_ERR="NO_COMMISSION"

if [ -f "${CONFIG_DIR}/notification.sh" ]; then
    source ${CONFIG_DIR}/notification.sh
fi

network_up_and_synced () {
    local NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" $NODE/status)

    if (( $NODE_STATUS_CODE != 200 )); then
        notify_chain_node_not_reachable $NODE
        exit 1
    fi

    local CHAIN_STATUS=$(curl -s ${NODE}/status)
    local CHAIN_ID=$(echo $CHAIN_STATUS | jq -r '.result.node_info.network')

    local CHAIN_SYNC_STATE=$(echo $CHAIN_STATUS | jq '.result.sync_info.catching_up')
    if [[ "$CHAIN_SYNC_STATE" == "true" ]]
    then
        
        notify_chain_syncing $CHAIN_ID
        exit 2
    fi

    local LATEST_BLOCK_TIME=$(echo $CHAIN_STATUS | jq -r '.result.sync_info.latest_block_time')

    local CONTROL_TIMESTAMP=$(date -d "-180 seconds" +%s)
    local BLOCK_TIMESTAMP=$(date -d "${LATEST_BLOCK_TIME}" +%s)

    if [ "$BLOCK_TIMESTAMP" -lt "$CONTROL_TIMESTAMP" ];
    then
        notify_chain_not_growing $CHAIN_ID "$BLOCK_TIMESTAMP" "$CONTROL_TIMESTAMP"
        exit 3
    fi 

    echo $CHAIN_STATUS | jq -r '.result.sync_info.latest_block_height | tonumber'
}

check_storage_node () {
    local STORAGE_NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" $STORAGE_NODE)

    if (( $NODE_STATUS_CODE != 200 )); then
        notify_storage_node_not_reachable $NODE
        exit 4
    fi
}

get_height_commission () {
    local HEIGHT=$1
    local DENOM=$2

    VALIDATOR_COMMISSION_OUTPUT=$($PATH_TO_SERVICE q distribution commission ${VALIDATOR_ADDRESS} --output json --node $NODE --height $HEIGHT)

    if [ $? -eq 0 ]; then
        local COMMISSION=$(echo "$VALIDATOR_COMMISSION_OUTPUT" | \
        /usr/bin/jq ".commission[] | select(.denom | contains(\"$DENOM\")).amount | tonumber")

        if [[ $COMMISSION =~ $NUMBER_RE ]] ; then
            echo $COMMISSION
            return
        fi  
    else
        echo $NO_COMMISSION_ERR
        return     
    fi

    echo $NO_COMMISSION_ERR
}

save_validator_data () {
    local VALIDATOR_DATA_FILE=$1
    local HEIGHT=$2   
    local HEIGHT_COMMISSION=$3
    
    echo "{\"last_height\": $HEIGHT, \"height_commission\": \"$HEIGHT_COMMISSION\"}" > $VALIDATOR_DATA_FILE
}

get_last_height () {
    local VALIDATOR_DATA_FILE=$1

    cat $VALIDATOR_DATA_FILE | jq ".last_height"
}

get_last_height_commission () {
    local VALIDATOR_DATA_FILE=${1}

    local HEIGHT_COMMISSION=$(cat $VALIDATOR_DATA_FILE | jq -r ".height_commission")
    if [ "$HEIGHT_COMMISSION" != "$NO_COMMISSION_ERR" ] && 
        [ "$HEIGHT_COMMISSION" != "null" ] && 
        [ -v HEIGHT_COMMISSION ] && 
        [ ! -z "$HEIGHT_COMMISSION" ]
    then
        echo "GETTING LAST HEIGHT COMMISSION $HEIGHT_COMMISSION" >&2
        echo $HEIGHT_COMMISSION
    fi
}

notify () {
    local MESSAGE=$1 

    # Send notification message to notification service. "send_notification_message" should be implemented in the '../notification.sh'
    if [[ $(type -t send_notification_message) == function ]]; then
        send_notification_message "${MESSAGE}"
    fi    
}

notify_storage_node_not_reachable () {
    local NODE=$1

    local MESSAGE=$(cat <<-EOF
<b>[Error] Storage node is not reachable</b>
'Storage Node URL <b>$NODE</b>' is not reachable. 

Hostname: <b>$(hostname)</b>

Please examine <b>debug.log</b>.
EOF
)

    notify "${MESSAGE}"
}

notify_chain_node_not_reachable () {
    local NODE=$1

    local MESSAGE=$(cat <<-EOF
<b>[Error] Chain node is not reachable</b>
'Node URL <b>$NODE</b>' is not reachable. 

Hostname: <b>$(hostname)</b>

Please examine <b>debug.log</b>.
EOF
)
    notify "${MESSAGE}"
}

notify_chain_not_growing () {
    local CHAIN_ID=$1
    local BLOCK_TIME="${2}"
    local CONTROL_TIME="${3}"

    if [ "$NOTIFY_NOT_GROWING_DISABLE" = "true" ]; then
        return
    fi

    local MESSAGE=$(cat <<-EOF
<b>[Error] Chain height is not growing</b>
Chain height is not growing, something wrong, please check. 

Hostname: <b>$(hostname)</b>
Chain ID: <b>${CHAIN_ID}</b>
Chain time: <b>${BLOCK_TIME}</b>
Control time: <b>${CONTROL_TIME}</b>

Please examine <b>debug.log</b>.
EOF
)
    notify "${MESSAGE}"
}

notify_chain_syncing () {
    local CHAIN_ID=$1

    local MESSAGE=$(cat <<-EOF
<b>[Notice] Chain is still syncing</b>
Chain is still catching up. 

Hostname: <b>$(hostname)</b>
Chain ID: <b>${CHAIN_ID}</b>

Please examine <b>debug.log</b>.
EOF
)
    notify "${MESSAGE}"
}


