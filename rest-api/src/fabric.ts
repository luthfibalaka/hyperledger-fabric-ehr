/*
 * SPDX-License-Identifier: Apache-2.0
 */

import {
  Contract,
  DefaultEventHandlerStrategies,
  DefaultQueryHandlerStrategies,
  Gateway,
  GatewayOptions,
  Wallets,
  Network,
  Transaction,
  Wallet,
} from 'fabric-network';
import * as config from './config';
import { logger } from './logger';
import { handleError } from './errors';
import * as protos from 'fabric-protos';

/**
 * Creates an in memory wallet to hold credentials for an Hospital and Bpjs user
 *
 * In this sample there is a single user for each MSP ID to demonstrate how
 * a client app might submit transactions for different users
 *
 * Alternatively a REST server could use its own identity for all transactions,
 * or it could use credentials supplied in the REST requests
 */
export const createWallet = async (): Promise<Wallet> => {
  const wallet = await Wallets.newInMemoryWallet();

  const hospitalIdentity = {
    credentials: {
      certificate: config.certificateHospital,
      privateKey: config.privateKeyHospital,
    },
    mspId: config.mspIdHospital,
    type: 'X.509',
  };

  await wallet.put(config.mspIdHospital, hospitalIdentity);

  const bpjsIdentity = {
    credentials: {
      certificate: config.certificateBpjs,
      privateKey: config.privateKeyBpjs,
    },
    mspId: config.mspIdBpjs,
    type: 'X.509',
  };

  await wallet.put(config.mspIdBpjs, bpjsIdentity);

  return wallet;
};

/**
 * Create a Gateway connection
 *
 * Gateway instances can and should be reused rather than connecting to submit every transaction
 */
export const createGateway = async (
  connectionProfile: Record<string, unknown>,
  identity: string,
  wallet: Wallet
): Promise<Gateway> => {
  logger.debug({ connectionProfile, identity }, 'Configuring gateway');

  const gateway = new Gateway();

  const options: GatewayOptions = {
    wallet,
    identity,
    discovery: { enabled: true, asLocalhost: config.asLocalhost },
    eventHandlerOptions: {
      commitTimeout: config.commitTimeout,
      endorseTimeout: config.endorseTimeout,
      strategy: DefaultEventHandlerStrategies.PREFER_MSPID_SCOPE_ANYFORTX,
    },
    queryHandlerOptions: {
      timeout: config.queryTimeout,
      strategy: DefaultQueryHandlerStrategies.PREFER_MSPID_SCOPE_ROUND_ROBIN,
    },
  };

  await gateway.connect(connectionProfile, options);

  return gateway;
};

/**
 * Get the network which the ehr chaincode is running on
 *
 * In addion to getting the contract, the network will also be used to
 * start a block event listener
 */
export const getNetwork = async (gateway: Gateway): Promise<Network> => {
  const network = await gateway.getNetwork(config.channelName);
  return network;
};

/**
 * Get the ehr contract and the qscc system contract
 *
 * The system contract is used for the liveness REST endpoint
 */
export const getContracts = async (
  network: Network
): Promise<{ assetContract: Contract; qsccContract: Contract }> => {
  const assetContract = network.getContract(config.chaincodeName);
  const qsccContract = network.getContract('qscc');
  return { assetContract, qsccContract };
};

/**
 * Evaluate a transaction and handle any errors
 */
export const evatuateTransaction = async (
  contract: Contract,
  transactionName: string,
  ...transactionArgs: string[]
): Promise<Buffer> => {
  const transaction = contract.createTransaction(transactionName);
  const transactionId = transaction.getTransactionId();
  logger.trace({ transaction }, 'Evaluating transaction');

  try {
    const payload = await transaction.evaluate(...transactionArgs);
    logger.trace(
      { transactionId: transactionId, payload: payload.toString() },
      'Evaluate transaction response received'
    );
    return payload;
  } catch (err) {
    throw handleError(transactionId, err);
  }
};

/**
 * Submit a transaction and handle any errors
 */
export const submitTransaction = async (
  transaction: Transaction,
  ...transactionArgs: string[]
): Promise<Buffer> => {
  logger.trace({ transaction }, 'Submitting transaction');
  const txnId = transaction.getTransactionId();

  try {
    const payload = await transaction.submit(...transactionArgs);
    logger.trace(
      { transactionId: txnId, payload: payload.toString() },
      'Submit transaction response received'
    );
    return payload;
  } catch (err) {
    throw handleError(txnId, err);
  }
};

/**
 * Get the validation code of the specified transaction
 */
export const getTransactionValidationCode = async (
  qsccContract: Contract,
  transactionId: string
): Promise<string> => {
  const data = await evatuateTransaction(
    qsccContract,
    'GetTransactionByID',
    config.channelName,
    transactionId
  );

  const processedTransaction = protos.protos.ProcessedTransaction.decode(data);
  const validationCode =
    protos.protos.TxValidationCode[processedTransaction.validationCode];

  logger.debug({ transactionId }, 'Validation code: %s', validationCode);
  return validationCode;
};

/**
 * Get the current block height
 *
 * This example of using a system contract is used for the liveness REST
 * endpoint
 */
export const getBlockHeight = async (
  qscc: Contract
): Promise<number | Long.Long> => {
  const data = await qscc.evaluateTransaction(
    'GetChainInfo',
    config.channelName
  );
  const info = protos.common.BlockchainInfo.decode(data);
  const blockHeight = info.height;

  logger.debug('Current block height: %d', blockHeight);
  return blockHeight;
};
