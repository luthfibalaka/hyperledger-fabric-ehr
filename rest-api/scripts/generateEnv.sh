#!/usr/bin/env bash

#
# SPDX-License-Identifier: Apache-2.0
#

${AS_LOCAL_HOST:=true}

: "${TEST_NETWORK_HOME:=../..}"
: "${CONNECTION_PROFILE_FILE_HOSPITAL:=${TEST_NETWORK_HOME}/organizations/peerOrganizations/hospital.example.com/connection-hospital.json}"
: "${CERTIFICATE_FILE_HOSPITAL:=${TEST_NETWORK_HOME}/organizations/peerOrganizations/hospital.example.com/users/User1@hospital.example.com/msp/signcerts/User1@hospital.example.com-cert.pem}"
: "${PRIVATE_KEY_FILE_HOSPITAL:=${TEST_NETWORK_HOME}/organizations/peerOrganizations/hospital.example.com/users/User1@hospital.example.com/msp/keystore/priv_sk}"

: "${CONNECTION_PROFILE_FILE_BPJS:=${TEST_NETWORK_HOME}/organizations/peerOrganizations/bpjs.example.com/connection-bpjs.json}"
: "${CERTIFICATE_FILE_BPJS:=${TEST_NETWORK_HOME}/organizations/peerOrganizations/bpjs.example.com/users/User1@bpjs.example.com/msp/signcerts/User1@bpjs.example.com-cert.pem}"
: "${PRIVATE_KEY_FILE_BPJS:=${TEST_NETWORK_HOME}/organizations/peerOrganizations/bpjs.example.com/users/User1@bpjs.example.com/msp/keystore/priv_sk}"


cat << ENV_END > .env
# Generated .env file
# See src/config.ts for details of all the available configuration variables
#

LOG_LEVEL=info

PORT=3000

HLF_CERTIFICATE_HOSPITAL="$(cat ${CERTIFICATE_FILE_HOSPITAL} | sed -e 's/$/\\n/' | tr -d '\r\n')"

HLF_PRIVATE_KEY_HOSPITAL="$(cat ${PRIVATE_KEY_FILE_HOSPITAL} | sed -e 's/$/\\n/' | tr -d '\r\n')"

HLF_CERTIFICATE_BPJS="$(cat ${CERTIFICATE_FILE_BPJS} | sed -e 's/$/\\n/' | tr -d '\r\n')"

HLF_PRIVATE_KEY_BPJS="$(cat ${PRIVATE_KEY_FILE_BPJS} | sed -e 's/$/\\n/' | tr -d '\r\n')"

REDIS_PORT=6379

HOSPITAL_APIKEY=$(uuidgen)

BPJS_APIKEY=$(uuidgen)

ENV_END
 
if [ "${AS_LOCAL_HOST}" = "true" ]; then

cat << LOCAL_HOST_END >> .env
AS_LOCAL_HOST=true

HLF_CONNECTION_PROFILE_HOSPITAL=$(cat ${CONNECTION_PROFILE_FILE_HOSPITAL} | jq -c .)

HLF_CONNECTION_PROFILE_BPJS=$(cat ${CONNECTION_PROFILE_FILE_BPJS} | jq -c .)

REDIS_HOST=localhost

LOCAL_HOST_END

elif [ "${AS_LOCAL_HOST}" = "false" ]; then

cat << WITH_HOSTNAME_END >> .env
AS_LOCAL_HOST=false

HLF_CONNECTION_PROFILE_HOSPITAL=$(cat ${CONNECTION_PROFILE_FILE_HOSPITAL} | jq -c '.peers["peer0.hospital.example.com"].url = "grpcs://peer0.hospital.example.com:7051" | .certificateAuthorities["ca.hospital.example.com"].url = "https://ca.hospital.example.com:7054"')

HLF_CONNECTION_PROFILE_BPJS=$(cat ${CONNECTION_PROFILE_FILE_BPJS} | jq -c '.peers["peer0.bpjs.example.com"].url = "grpcs://peer0.bpjs.example.com:9051" | .certificateAuthorities["ca.bpjs.example.com"].url = "https://ca.bpjs.example.com:8054"')

REDIS_HOST=redis

WITH_HOSTNAME_END

fi
