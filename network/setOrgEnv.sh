#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0




# default to using Hospital
ORG=${1:-Hospital}

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

ORDERER_CA=${DIR}/test-network/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
PEER0_HOSPITAL_CA=${DIR}/test-network/organizations/peerOrganizations/hospital.example.com/tlsca/tlsca.hospital.example.com-cert.pem
PEER0_BPJS_CA=${DIR}/test-network/organizations/peerOrganizations/bpjs.example.com/tlsca/tlsca.bpjs.example.com-cert.pem


if [[ ${ORG,,} == "hospital" || ${ORG,,} == "digibank" ]]; then

   CORE_PEER_LOCALMSPID=HospitalMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/hospital.example.com/users/Admin@hospital.example.com/msp
   CORE_PEER_ADDRESS=localhost:7051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/test-network/organizations/peerOrganizations/hospital.example.com/tlsca/tlsca.hospital.example.com-cert.pem

elif [[ ${ORG,,} == "bpjs" || ${ORG,,} == "magnetocorp" ]]; then

   CORE_PEER_LOCALMSPID=BpjsMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/bpjs.example.com/users/Admin@bpjs.example.com/msp
   CORE_PEER_ADDRESS=localhost:9051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/test-network/organizations/peerOrganizations/bpjs.example.com/tlsca/tlsca.bpjs.example.com-cert.pem

else
   echo "Unknown \"$ORG\", please choose Hospital/Digibank or Bpjs/Magnetocorp"
   echo "For example to get the environment variables to set upa Bpjs shell environment run:  ./setOrgEnv.sh Bpjs"
   echo
   echo "This can be automated to set them as well with:"
   echo
   echo 'export $(./setOrgEnv.sh Bpjs | xargs)'
   exit 1
fi

# output the variables that need to be set
echo "CORE_PEER_TLS_ENABLED=true"
echo "ORDERER_CA=${ORDERER_CA}"
echo "PEER0_HOSPITAL_CA=${PEER0_HOSPITAL_CA}"
echo "PEER0_BPJS_CA=${PEER0_BPJS_CA}"

echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"

echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
