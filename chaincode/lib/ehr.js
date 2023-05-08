/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

// Deterministic JSON.stringify()
const stringify  = require('json-stringify-deterministic');
const sortKeysRecursive  = require('sort-keys-recursive');
const { Contract } = require('fabric-contract-api');

class AssetTransfer extends Contract {

    async InitLedger(ctx) {
        const ehrs = [
            {
                ID: '1',
                Name: 'Andi',
                DateOfBirth: new Date(2002,11,4).toDateString(),
                Gender: 1,
                Address: 'Perum. Blablabla',
                PhoneNumber: '081212345678',
                Insurance: 'BPJS',
                Medication: ['Panadol', 'Paracetamol'],
                Diagnosis: ['pusing', 'demam'],
            },
            {
                ID: '2',
                Name: 'Susi',
                DateOfBirth: new Date(2002,1,4).toDateString(),
                Gender: 0,
                Address: 'Perum. Blablabla 2',
                PhoneNumber: '081212348888',
                Insurance: "Alliance",
                Medication: ['Panadol'],
                Diagnosis: ['pusing'],
            },
        ];

        for (const ehr of ehrs) {
            ehr.docType = 'ehr';
            await ctx.stub.putState(ehr.ID, Buffer.from(stringify(sortKeysRecursive(ehr))));
        }
    }

    async CreateEhr(
        ctx,
        id,
        name,
        dateOfBirth,
        gender,
        address,
        phoneNumber,
        insurance,
        medication,
        diagnosis,
    ) {
        const MSPID = await ctx.clientIdentity.getMSPID();
        if (MSPID.toLowerCase() === "org1msp") {
            throw new Error('Forbidden access');
        }

        const exists = await this.EhrExists(ctx, id);
        if (exists) {
            throw new Error(`The ehr ${id} already exists`);
        }

        const ehr = {
            ID: id,
            Name: name,
            DateOfBirth: dateOfBirth,
            Gender: gender,
            Address: address,
            PhoneNumber: phoneNumber,
            Insurance: insurance,
            Medication: medication,
            Diagnosis: diagnosis,
        };
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(ehr))));
        return JSON.stringify(ehr);
    }

	async ReadEhrHistory(ctx, id) {
        const MSPID = await ctx.clientIdentity.getMSPID();
        if (MSPID.toLowerCase() === "org1msp") {
            const ehrData = JSON.parse(await this.ReadEhr(ctx, id));
            if (ehrData.Insurance !== "BPJS") {
                return JSON.stringify({});
            }
        }

		let resultsIterator = await ctx.stub.getHistoryForKey(id);
		let results = await this._GetAllResults(resultsIterator, true);
		return JSON.stringify(results);
	}

    async _GetAllResults(iterator, isHistory) {
		let allResults = [];
		let res = await iterator.next();
		while (!res.done) {
			if (res.value && res.value.value.toString()) {
				let jsonRes = {};
				console.log(res.value.value.toString('utf8'));
				if (isHistory && isHistory === true) {
					jsonRes.TxId = res.value.txId;
					jsonRes.Timestamp = res.value.timestamp;
					try {
						jsonRes.Value = JSON.parse(res.value.value.toString('utf8'));
					} catch (err) {
						console.log(err);
						jsonRes.Value = res.value.value.toString('utf8');
					}
				} else {
					jsonRes.Key = res.value.key;
					try {
						jsonRes.Record = JSON.parse(res.value.value.toString('utf8'));
					} catch (err) {
						console.log(err);
						jsonRes.Record = res.value.value.toString('utf8');
					}
				}
				allResults.push(jsonRes);
			}
			res = await iterator.next();
		}
		iterator.close();
		return allResults;
	}

    async ReadEhr(ctx, id) {
        let assetJSON = await ctx.stub.getState(id);
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The asset ${id} does not exist`);
        }

        const MSPID = await ctx.clientIdentity.getMSPID();
        if (MSPID.toLowerCase() === "org1msp" && JSON.parse(assetJSON).Insurance !== "BPJS") {
            assetJSON = JSON.stringify({})
        }
        return assetJSON.toString();
    }

    async UpdateEhr(
        ctx,
        id,
        name,
        dateOfBirth,
        gender,
        address,
        phoneNumber,
        insurance,
        medication,
        diagnosis,
    ) {
        const MSPID = await ctx.clientIdentity.getMSPID();
        if (MSPID.toLowerCase() === "org1msp") {
            throw new Error('Forbidden access');
        }

        const exists = await this.EhrExists(ctx, id);
        if (!exists) {
            throw new Error(`The ehr ${id} does not exist`);
        }

        const updatedEhr = {
            ID: id,
            Name: name,
            DateOfBirth: dateOfBirth,
            Gender: gender,
            Address: address,
            PhoneNumber: phoneNumber,
            Insurance: insurance,
            Medication: medication,
            Diagnosis: diagnosis,
        };
        return ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(updatedEhr))));
    }

    async DeleteEhr(ctx, id) {
        const MSPID = await ctx.clientIdentity.getMSPID();
        if (MSPID.toLowerCase() === "org1msp") {
            throw new Error('Forbidden access');
        }

        const exists = await this.EhrExists(ctx, id);
        if (!exists) {
            throw new Error(`The ehr ${id} does not exist`);
        }
        return ctx.stub.deleteState(id);
    }

    async EhrExists(ctx, id) {
        const assetJSON = await ctx.stub.getState(id);
        return assetJSON && assetJSON.length > 0;
    }

    async GetAllEhrs(ctx) {
        const allResults = [];
        const MSPID = await ctx.clientIdentity.getMSPID();
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            let authorized = true;
            try {
                record = JSON.parse(strValue);
                if (MSPID.toLowerCase() === "bpjsmsp" && record.Insurance !== "BPJS") {
                    authorized = false;
                }
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            if (authorized) {
                allResults.push(record);
            }
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }
}

module.exports = AssetTransfer;
