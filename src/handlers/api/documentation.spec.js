const chai = require('chai');
chai.use(require('chai-as-promised'));

const { expect } = chai;
const sinon = require('sinon');

const { handler } = require('./documentation');

describe('src/handlers/api/documentation.js', async () => {
  const sandbox = sinon.createSandbox();

  beforeEach(() => {
    sandbox.restore();
  });

  after(() => {
    sandbox.restore();
  });

  it('should return the openapi spec as html', async () => {
    const res = await handler({});
    const spec = res.body;
    expect(spec).includes('<html>');
  });

  it('should return the openapi spec as json', async () => {
    const res = await handler({ queryStringParameters: { format: 'json' } });
    const spec = res;
    expect(spec.info.title).to.equal('serverless-app');
  });
});
