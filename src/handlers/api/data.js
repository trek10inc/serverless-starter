const config = require('../../libs/config');

const { dbc } = require('../../libs/aws');

/**
 * @param {import('aws-lambda').APIGatewayProxyEventV2} event
 * @param {import('aws-lambda').Context} context
 * @returns {Promise<import('aws-lambda').APIGatewayProxyResultV2>}
 */
/* eslint-disable no-unused-vars */
exports.handler = async (event, context) => {
  const data = await dbc.scan({
    TableName: config.tableName,
  }).promise();
  const res = {
    items: data.Items,
    message: 'hello, world!',
    foo: 'bar',
  };
  return res;
};
