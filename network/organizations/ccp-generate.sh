#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG="hospital"
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/hospital.example.com/tlsca/tlsca.hospital.example.com-cert.pem
CAPEM=organizations/peerOrganizations/hospital.example.com/ca/ca.hospital.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/hospital.example.com/connection-hospital.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/hospital.example.com/connection-hospital.yaml

ORG="bpjs"
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/bpjs.example.com/tlsca/tlsca.bpjs.example.com-cert.pem
CAPEM=organizations/peerOrganizations/bpjs.example.com/ca/ca.bpjs.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/bpjs.example.com/connection-bpjs.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/bpjs.example.com/connection-bpjs.yaml
