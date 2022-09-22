const AWS = require('aws-sdk');

const dbc = new AWS.DynamoDB.DocumentClient();

module.exports = {
  dbc,
};
