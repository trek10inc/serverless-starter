const fs = require('fs');
const path = require('path');

/**
 * @param {import('aws-lambda').APIGatewayProxyEventV2} event
 * @param {import('aws-lambda').Context} context
 * @returns {Promise<import('aws-lambda').APIGatewayProxyResultV2>}
 */
/* eslint-disable-next-line no-unused-vars */
exports.handler = async (event, context) => {
  const queryStringParameters = event.queryStringParameters || {};
  const spec = JSON.parse(fs.readFileSync(path.join(__dirname, '../../openapi.packaged.json')).toString());

  spec.info.title = process.env.APPLICATION_NAME;

  if (queryStringParameters.format === 'json') {
    return spec;
  }

  const { title } = spec.info;
  const html = fs.readFileSync(path.join(__dirname, './assets/openapi-template.html')).toString()
    .replace('$title', title)
    .replace('$spec', JSON.stringify(spec));

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html',
    },
    body: html,
  };
};
