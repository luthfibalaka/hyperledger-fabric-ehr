#!/bin/bash

function createHospital() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/hospital.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/hospital.example.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-hospital --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-hospital.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-hospital.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-hospital.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-hospital.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/hospital.example.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy hospital's CA cert to hospital's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/hospital.example.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem" "${PWD}/organizations/peerOrganizations/hospital.example.com/msp/tlscacerts/ca.crt"

  # Copy hospital's CA cert to hospital's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/hospital.example.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem" "${PWD}/organizations/peerOrganizations/hospital.example.com/tlsca/tlsca.hospital.example.com-cert.pem"

  # Copy hospital's CA cert to hospital's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/hospital.example.com/ca"
  cp "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem" "${PWD}/organizations/peerOrganizations/hospital.example.com/ca/ca.hospital.example.com-cert.pem"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-hospital --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-hospital --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-hospital --id.name hospitaladmin --id.secret hospitaladminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-hospital -M "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/hospital.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/msp/config.yaml"

  infoln "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-hospital -M "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls" --enrollment.profile tls --csr.hosts peer0.hospital.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/hospital.example.com/peers/peer0.hospital.example.com/tls/server.key"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-hospital -M "${PWD}/organizations/peerOrganizations/hospital.example.com/users/User1@hospital.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/hospital.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/hospital.example.com/users/User1@hospital.example.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://hospitaladmin:hospitaladminpw@localhost:7054 --caname ca-hospital -M "${PWD}/organizations/peerOrganizations/hospital.example.com/users/Admin@hospital.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/hospital/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/hospital.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/hospital.example.com/users/Admin@hospital.example.com/msp/config.yaml"
}

function createBpjs() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/bpjs.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/bpjs.example.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-bpjs --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bpjs.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bpjs.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bpjs.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bpjs.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/bpjs.example.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy bpjs's CA cert to bpjs's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/bpjs.example.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem" "${PWD}/organizations/peerOrganizations/bpjs.example.com/msp/tlscacerts/ca.crt"

  # Copy bpjs's CA cert to bpjs's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/bpjs.example.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem" "${PWD}/organizations/peerOrganizations/bpjs.example.com/tlsca/tlsca.bpjs.example.com-cert.pem"

  # Copy bpjs's CA cert to bpjs's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/bpjs.example.com/ca"
  cp "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem" "${PWD}/organizations/peerOrganizations/bpjs.example.com/ca/ca.bpjs.example.com-cert.pem"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-bpjs --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-bpjs --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-bpjs --id.name bpjsadmin --id.secret bpjsadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-bpjs -M "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/bpjs.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/msp/config.yaml"

  infoln "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-bpjs -M "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls" --enrollment.profile tls --csr.hosts peer0.bpjs.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/bpjs.example.com/peers/peer0.bpjs.example.com/tls/server.key"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-bpjs -M "${PWD}/organizations/peerOrganizations/bpjs.example.com/users/User1@bpjs.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/bpjs.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/bpjs.example.com/users/User1@bpjs.example.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://bpjsadmin:bpjsadminpw@localhost:8054 --caname ca-bpjs -M "${PWD}/organizations/peerOrganizations/bpjs.example.com/users/Admin@bpjs.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/bpjs/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/bpjs.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/bpjs.example.com/users/Admin@bpjs.example.com/msp/config.yaml"
}

function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/example.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/example.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy orderer org's CA cert to orderer org's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/example.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  # Copy orderer org's CA cert to orderer org's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/ordererOrganizations/example.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml"

  infoln "Generating the orderer-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls" --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the orderer's tls directory that are referenced by orderer startup config
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key"

  # Copy orderer org's CA cert to orderer's /msp/tlscacerts directory (for use in the orderer MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml"
}
