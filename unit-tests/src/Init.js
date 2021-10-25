import path from "path";
import { init } from "flow-js-testing";

describe("test setup", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../contracts");
    await init(basePath);

    // alternatively you can pass specific port
    // await init(basePath, {port: 8085})
  });
});