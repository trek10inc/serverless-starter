const chai = require('chai');
chai.use(require('chai-as-promised'));

const { expect } = chai;
const sinon = require('sinon');

const { handler } = require('./authorizer');

describe('src/handlers/auth/authorizer.js', async () => {
  const sandbox = sinon.createSandbox();

  beforeEach(() => {
    sandbox.restore();
  });

  after(() => {
    sandbox.restore();
  });

  it('should return the openapi spec as html', async () => {
    const res = await handler({
      headers: {
        authorization: 'abc123',
      },
    });
    expect(res.isAuthorized).to.equal(true);
  });
});
