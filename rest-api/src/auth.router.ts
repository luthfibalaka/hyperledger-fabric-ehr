import express, { Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { getReasonPhrase, StatusCodes } from 'http-status-codes';
import { logger } from './logger';
import * as env from 'env-var';

const { UNAUTHORIZED, OK, BAD_REQUEST } = StatusCodes;

export const authRouter = express.Router();

authRouter.post(
  '/',
  body().isObject().withMessage('body must contain email and password'),
  body('email', 'must be a string').notEmpty(),
  body('password', 'must be a string').notEmpty(),
  async (req: Request, res: Response) => {
    logger.debug(req.body, 'Login request received');

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

    const email = req.body.email as string;
    const password = req.body.password as string;

    if (
      email === env.get('EMAIL_HOSPITAL').asString() &&
      password === env.get('PASSWORD_HOSPITAL').asString()
    ) {
      return res.status(OK).json({
        status: getReasonPhrase(OK),
        x_api_key: env.get('HOSPITAL_APIKEY').asString(),
        role: 'hospital_admin',
      });
    } else if (
      email === env.get('EMAIL_BPJS').asString() &&
      password === env.get('PASSWORD_BPJS').asString()
    ) {
      return res.status(OK).json({
        status: getReasonPhrase(OK),
        x_api_key: env.get('BPJS_APIKEY').asString(),
        role: 'bpjs_admin',
      });
    } else {
      return res.status(UNAUTHORIZED).json({
        status: getReasonPhrase(UNAUTHORIZED),
      });
    }
  }
);
