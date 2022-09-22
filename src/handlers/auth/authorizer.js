/* See the following for more information:
- https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html
- https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html
*/

/**
 * @param {import('aws-lambda').APIGatewayProxyEventV2} event
 * @param {import('aws-lambda').Context} context
 * @returns {Promise<import('aws-lambda').APIGatewaySimpleAuthorizerResult | import('aws-lambda').APIGatewayAuthorizerResult>}
 */
/* eslint-disable no-unused-vars */
exports.handler = async (event, context) => {
  const requestToken = event?.headers?.authorization;
  return {
    isAuthorized: requestToken !== undefined,
  };
};
