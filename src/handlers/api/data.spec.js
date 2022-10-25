const chai = require('chai');
chai.use(require('chai-as-promised'));

const { expect } = chai;
const sinon = require('sinon');

const { handler } = require('./data');
const { dbc } = require('../../libs/aws');
const config = require('../../libs/config');

describe('src/handlers/api/data.js', async () => {
  const sandbox = sinon.createSandbox();

  beforeEach(() => {
    sandbox.restore();
  });

  after(() => {
    sandbox.restore();
  });

  it('should call the DyanmoDB scan() API', async () => {
    sandbox.stub(config, 'tableName').value('dummy');
    sandbox.stub(dbc, 'scan').returns({
      promise: sandbox.stub().resolves({
        Items: [{ id: '123' }],
        LastEvaluatedKey: undefined,
      }),
    });
    const res = await handler();
    expect(res).deep.equals({
      items: [{ id: '123' }],
      message: 'hello, world!',
      foo: 'bar',
    });
    sinon.assert.calledOnceWithExactly(dbc.scan, {
      TableName: 'dummy',
    });
  });
});
