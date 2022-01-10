/* eslint-disable no-undef */
import path from 'path';
import { emulator, init } from 'flow-js-testing';

jest.setTimeout(10000);

describe('unit-tests', () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../');
    const port = 8080;
    const logging = false;
    await init(basePath, { port });
    return emulator.start(port, logging);
  });

  afterEach(async () => {
    return emulator.stop();
  });

  test('shall format single info line properly', async () => {
    const msg = 'Hello, world!';
    const output = emulator.parseDataBuffer(msg);
    expect(output).toEqual({});
  });

  test('shall format logged message', () => {
    const msg = `time="2021-11-03T18:06:56+05:00" level=info msg=" Starting gRPC server on port 3569" port=3569`;
    const output = emulator.parseDataBuffer(msg);
    expect(output.level).toBe('info');
  });
});
