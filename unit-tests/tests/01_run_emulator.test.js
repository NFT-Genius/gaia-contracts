import path from "path";
import { emulator, init } from "flow-js-testing";

describe("test setup", () => {  
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../contracts");
    const port = 8080;

    await init(basePath, { port });
    await emulator.start(port);
  });

  afterEach(async () => {
    await emulator.stop();
  });

  test("basic test", async () => {
    // Turn on logging from begining
    emulator.setLogging(true);
    // some asserts and interactions
    
    // Turn off logging for later calls
    emulator.setLogging(false);
    // more asserts and interactions here
  });
});