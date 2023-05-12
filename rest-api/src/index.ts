/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * This is the main entrypoint for the REST server, which is responsible
 * for connecting to the Fabric network and setting up a job queue for
 * processing submit transactions
 */

import * as config from './config';
import {
  createGateway,
  createWallet,
  getContracts,
  getNetwork,
} from './fabric';
import {
  initJobQueue,
  initJobQueueScheduler,
  initJobQueueWorker,
} from './jobs';
import { logger } from './logger';
import { createServer } from './server';
import { isMaxmemoryPolicyNoeviction } from './redis';
import { Queue, QueueScheduler, Worker } from 'bullmq';

let jobQueue: Queue | undefined;
let jobQueueWorker: Worker | undefined;
let jobQueueScheduler: QueueScheduler | undefined;

async function main() {
  logger.info('Checking Redis config');
  if (!(await isMaxmemoryPolicyNoeviction())) {
    throw new Error(
      'Invalid redis configuration: redis instance must have the setting maxmemory-policy=noeviction'
    );
  }

  logger.info('Creating REST server');
  const app = await createServer();

  logger.info('Connecting to Fabric network with hospital mspid');
  const wallet = await createWallet();

  const gatewayHospital = await createGateway(
    config.connectionProfileHospital,
    config.mspIdHospital,
    wallet
  );
  const networkHospital = await getNetwork(gatewayHospital);
  const contractsHospital = await getContracts(networkHospital);

  app.locals[config.mspIdHospital] = contractsHospital;

  logger.info('Connecting to Fabric network with bpjs mspid');
  const gatewayBpjs = await createGateway(
    config.connectionProfileBpjs,
    config.mspIdBpjs,
    wallet
  );
  const networkBpjs = await getNetwork(gatewayBpjs);
  const contractsBpjs = await getContracts(networkBpjs);

  app.locals[config.mspIdBpjs] = contractsBpjs;

  logger.info('Initialising submit job queue');
  jobQueue = initJobQueue();
  jobQueueWorker = initJobQueueWorker(app);
  if (config.submitJobQueueScheduler === true) {
    logger.info('Initialising submit job queue scheduler');
    jobQueueScheduler = initJobQueueScheduler();
  }
  app.locals.jobq = jobQueue;

  logger.info('Starting REST server');
  app.listen(config.port, '0.0.0.0', () => {
    logger.info('REST server started on port: %d', config.port);
  });
}

main().catch(async (err) => {
  logger.error({ err }, 'Unxepected error');

  if (jobQueueScheduler != undefined) {
    logger.debug('Closing job queue scheduler');
    await jobQueueScheduler.close();
  }

  if (jobQueueWorker != undefined) {
    logger.debug('Closing job queue worker');
    await jobQueueWorker.close();
  }

  if (jobQueue != undefined) {
    logger.debug('Closing job queue');
    await jobQueue.close();
  }
});
