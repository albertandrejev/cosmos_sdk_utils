# Cosmos SDK based network spamming script

This script should be used to spam Cosmos SDK based networks.

### Usage

In order to run you need to provide 7 mandatory and 3 optional parameters

```
./spam_network.sh \
    <Path to network service exectuable> \
    <Password for the used account key> \
    <Account address, it also will be used as from address for send transaction> \
    <To address for send transaction> \
    <Chain ID> \
    <Memo for the transaction> \
    <Fee denomination, for example `uatom`> \
    <Amount of tokens to send. Optional, default value is 200> \
    <Fee amount. Optional, default value is 200> \
    <RPC node address. Optional, default value is "http://localhost:26657">
```
