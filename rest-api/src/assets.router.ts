/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * This code is modified from basic asset transfer example
 *
 * To avoid timeouts, long running tasks should be decoupled from HTTP request
 * processing
 *
 * Submit transactions can potentially be very long running, especially if the
 * transaction fails and needs to be retried one or more times
 *
 * To allow requests to respond quickly enough, this sample queues submit
 * requests for processing asynchronously and immediately returns 202 Accepted
 */

import express, { Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { Contract } from 'fabric-network';
import { getReasonPhrase, StatusCodes } from 'http-status-codes';
import { Queue } from 'bullmq';
import { AssetNotFoundError } from './errors';
import { evatuateTransaction } from './fabric';
import { addSubmitTransactionJob } from './jobs';
import { logger } from './logger';

const { ACCEPTED, BAD_REQUEST, INTERNAL_SERVER_ERROR, NOT_FOUND, OK } =
  StatusCodes;

export const assetsRouter = express.Router();

assetsRouter.get('/', async (req: Request, res: Response) => {
  logger.debug('Get all ehrs request received');
  try {
    const mspId = req.user as string;
    const contract = req.app.locals[mspId]?.assetContract as Contract;

    const data = await evatuateTransaction(contract, 'GetAllEhrs');
    let ehrs = [];
    if (data.length > 0) {
      ehrs = JSON.parse(data.toString());
    }

    return res.status(OK).json(ehrs);
  } catch (err) {
    logger.error({ err }, 'Error processing get all ehrs request');
    return res.status(INTERNAL_SERVER_ERROR).json({
      status: getReasonPhrase(INTERNAL_SERVER_ERROR),
      timestamp: new Date().toISOString(),
    });
  }
});

assetsRouter.post(
  '/',
  body().isObject().withMessage('body must contain an ehr object'),
  body('ID', 'must be a string').notEmpty(),
  body('Name', 'must be a string').notEmpty(),
  body('DateOfBirth', 'must be a valid date string').notEmpty(),
  body('Gender', 'must be a number (0: Female, 1: Male)').isNumeric(),
  body('Address', 'must be a string').notEmpty(),
  body('PhoneNumber', 'must be a string').notEmpty(),
  body('Insurance', 'must be a string').notEmpty(),
  body('Medication', 'must be an array of string').isArray(),
  body('Diagnosis', 'must be an array of string').isArray(),
  async (req: Request, res: Response) => {
    logger.debug(req.body, 'Create ehr request received');

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(BAD_REQUEST).json({
        status: getReasonPhrase(BAD_REQUEST),
        reason: 'VALIDATION_ERROR',
        message: 'Invalid request body',
        timestamp: new Date().toISOString(),
        errors: errors.array(),
      });
    }

    const mspId = req.user as string;
    const ehrId = req.body.ID;

    try {
      const submitQueue = req.app.locals.jobq as Queue;
      const jobId = await addSubmitTransactionJob(
        submitQueue,
        mspId,
        'CreateEhr',
        ehrId,
        req.body.Name,
        req.body.DateOfBirth,
        req.body.Gender,
        req.body.Address,
        req.body.PhoneNumber,
        req.body.Insurance,
        req.body.Medication,
        req.body.Diagnosis
      );

      return res.status(ACCEPTED).json({
        status: getReasonPhrase(ACCEPTED),
        jobId: jobId,
        timestamp: new Date().toISOString(),
      });
    } catch (err) {
      logger.error(
        { err },
        'Error processing create ehr request for ehr ID %s',
        ehrId
      );

      return res.status(INTERNAL_SERVER_ERROR).json({
        status: getReasonPhrase(INTERNAL_SERVER_ERROR),
        timestamp: new Date().toISOString(),
      });
    }
  }
);

assetsRouter.options('/:ehrId', async (req: Request, res: Response) => {
  const ehrId = req.params.ehrId;
  logger.debug('Ehr options request received for ehr ID %s', ehrId);

  try {
    const mspId = req.user as string;
    const contract = req.app.locals[mspId]?.assetContract as Contract;

    const data = await evatuateTransaction(contract, 'EhrExists', ehrId);
    const exists = data.toString() === 'true';

    if (exists) {
      return res
        .status(OK)
        .set({
          Allow: 'DELETE,GET,OPTIONS,PATCH,PUT',
        })
        .json({
          status: getReasonPhrase(OK),
          timestamp: new Date().toISOString(),
        });
    } else {
      return res.status(NOT_FOUND).json({
        status: getReasonPhrase(NOT_FOUND),
        timestamp: new Date().toISOString(),
      });
    }
  } catch (err) {
    logger.error(
      { err },
      'Error processing ehr options request for ehr ID %s',
      ehrId
    );
    return res.status(INTERNAL_SERVER_ERROR).json({
      status: getReasonPhrase(INTERNAL_SERVER_ERROR),
      timestamp: new Date().toISOString(),
    });
  }
});

assetsRouter.get('/:ehrId', async (req: Request, res: Response) => {
  const ehrId = req.params.ehrId;
  logger.debug('Read ehr request received for ehr ID %s', ehrId);

  try {
    const mspId = req.user as string;
    const contract = req.app.locals[mspId]?.assetContract as Contract;

    const data = await evatuateTransaction(contract, 'ReadEhr', ehrId);
    const ehr = JSON.parse(data.toString());

    const data2 = await evatuateTransaction(contract, 'ReadEhrHistory', ehrId);
    const ehrHistory = JSON.parse(data2.toString());

    return res.status(OK).json({ ehr, ehrHistory });
  } catch (err) {
    logger.error(
      { err },
      'Error processing read ehr request for ehr ID %s',
      ehrId
    );

    if (err instanceof AssetNotFoundError) {
      return res.status(NOT_FOUND).json({
        status: getReasonPhrase(NOT_FOUND),
        timestamp: new Date().toISOString(),
      });
    }

    return res.status(INTERNAL_SERVER_ERROR).json({
      status: getReasonPhrase(INTERNAL_SERVER_ERROR),
      timestamp: new Date().toISOString(),
    });
  }
});

assetsRouter.put(
  '/:ehrId',
  body().isObject().withMessage('body must contain an ehr object'),
  body('ID', 'must be a string').notEmpty(),
  body('Name', 'must be a string').notEmpty(),
  body('DateOfBirth', 'must be a valid date string').notEmpty(),
  body('Gender', 'must be a number (0: Female, 1: Male)').isNumeric(),
  body('Address', 'must be a string').notEmpty(),
  body('PhoneNumber', 'must be a string').notEmpty(),
  body('Insurance', 'must be a string').notEmpty(),
  body('Medication', 'must be an array of string').isArray(),
  body('Diagnosis', 'must be an array of string').isArray(),
  async (req: Request, res: Response) => {
    logger.debug(req.body, 'Update ehr request received');

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(BAD_REQUEST).json({
        status: getReasonPhrase(BAD_REQUEST),
        reason: 'VALIDATION_ERROR',
        message: 'Invalid request body',
        timestamp: new Date().toISOString(),
        errors: errors.array(),
      });
    }

    if (req.params.ehrId != req.body.ID) {
      return res.status(BAD_REQUEST).json({
        status: getReasonPhrase(BAD_REQUEST),
        reason: 'ASSET_ID_MISMATCH',
        message: 'Asset IDs must match',
        timestamp: new Date().toISOString(),
      });
    }

    const mspId = req.user as string;
    const ehrId = req.params.ehrId;

    try {
      const submitQueue = req.app.locals.jobq as Queue;
      const jobId = await addSubmitTransactionJob(
        submitQueue,
        mspId,
        'UpdateEhr',
        ehrId,
        req.body.Name,
        req.body.DateOfBirth,
        req.body.Gender,
        req.body.Address,
        req.body.PhoneNumber,
        req.body.Insurance,
        req.body.Medication,
        req.body.Diagnosis
      );

      return res.status(ACCEPTED).json({
        status: getReasonPhrase(ACCEPTED),
        jobId: jobId,
        timestamp: new Date().toISOString(),
      });
    } catch (err) {
      logger.error(
        { err },
        'Error processing update ehr request for ehr ID %s',
        ehrId
      );

      return res.status(INTERNAL_SERVER_ERROR).json({
        status: getReasonPhrase(INTERNAL_SERVER_ERROR),
        timestamp: new Date().toISOString(),
      });
    }
  }
);

assetsRouter.delete('/:ehrId', async (req: Request, res: Response) => {
  logger.debug(req.body, 'Delete ehr request received');

  const mspId = req.user as string;
  const ehrId = req.params.ehrId;

  try {
    const submitQueue = req.app.locals.jobq as Queue;
    const jobId = await addSubmitTransactionJob(
      submitQueue,
      mspId,
      'DeleteEhr',
      ehrId
    );

    return res.status(ACCEPTED).json({
      status: getReasonPhrase(ACCEPTED),
      jobId: jobId,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    logger.error(
      { err },
      'Error processing delete ehr request for ehr ID %s',
      ehrId
    );

    return res.status(INTERNAL_SERVER_ERROR).json({
      status: getReasonPhrase(INTERNAL_SERVER_ERROR),
      timestamp: new Date().toISOString(),
    });
  }
});
