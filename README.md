# hyperledger-fabric-ehr

This is an EHR implementation using Hyperledger Fabric

# Guide

There are 2 steps to run the whole system. Before doing any of these steps, make sure every preprequisites mentioned [here](https://hyperledger-fabric.readthedocs.io/en/release-2.5/prereqs.html) are installed. Also, make sure to run every commands from the root folder.

## 1. Run the Hyperledger Fabric network & deploy the chaincode

```
cd network/
./network.sh createChannel -ca
./network.sh deployCC -ccn basic -ccp ../chaincode/ -ccl javascript
```

Optionally, you may populate the ledger with initial ehr data

```
# Make peer command available
export PATH=${PWD}/../bin:$PATH

# Add config needed
export FABRIC_CFG_PATH=$PWD/../config/

# Env to interact as Hospital
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="HospitalMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/hospital.example.com/users/Admin@hospital.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Initialize ledger data
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C ehr-channel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'

# Query to check if ehr data has been added
peer chaincode query -C ehr-channel -n basic -c '{"Args":["GetAllEhrs"]}'
```

To clean up after usage, run:

```
./network.sh down
```

## 2. Run the rest API

Download package-lock.json form [here](https://drive.google.com/file/d/1HHagYyDumBfz2HgsAuCcK2BY-iySpFtI/view?usp=sharing) by running `curl -L -o "package-lock.json" "https://drive.google.com/uc?export=download&id=1HHagYyDumBfz2HgsAuCcK2BY-iySpFtI"` and copy to `/rest-api` (to make sure docker build running correctly). Then, do the following:

```
cd rest-api/

# Generate needed env, take note of `*_APIKEY` from the generated `.env` file to be used as `x-api-key` header in request
AS_LOCAL_HOST=false npm run generateEnv

# Create the image
docker build -t rest-api .

# Run the rest API
docker-compose up -d
```

You can now access the EHR system from the Rest API! To learn how to use it, refer [here](https://www.postman.com/technical-geoscientist-15115418/workspace/ehr-sisdis)

# NOTES

1. Only Hospital organization can create, update, and delete EHR.
2. Read EHR not only return details of an EHR, but also its history of change (immutable).

# TODO

1. Login and frontend
