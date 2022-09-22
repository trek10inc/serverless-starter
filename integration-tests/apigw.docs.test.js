const axios = require('axios');
const chai = require('chai');
chai.use(require('chai-as-promised'));

const { expect } = chai;

describe('Calling API Gateway /docs endpoint', async () => {
  const apigwBaseUrl = process.env.API_ENDPOINT;
  const apigwEndpoint = `${apigwBaseUrl}docs`;

  it('should successfully return a text/html http response', async () => {
    const response = await axios.get(`${apigwEndpoint}`, {});

    expect(response.status).equals(200);
    expect(response.headers['content-type']).equals('text/html');
    expect(response.data.substring(0, 6)).equals('<html>');
  });
});
