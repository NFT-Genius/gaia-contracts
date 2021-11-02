import path from "path";
import { emulator, init } from "flow-js-testing";

jest.setTimeout(10000);

describe("unit-tests", ()=>{
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../cadence"); 
		const port = 8080; 
		const logging = false;    
    await init(basePath, { port });
    return emulator.start(port, logging);
  });
  
  afterEach(async () => {
    return emulator.stop();
  });
  
  test("+++", async () => {
    // WRITE YOUR ASSERTS HERE
  })
})
