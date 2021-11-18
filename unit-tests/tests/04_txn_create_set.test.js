import path from "path";
import { 
  emulator, 
  init, 
  shallPass,
  sendTransaction,
  deployContractByName,
  getServiceAddress,
} from "flow-js-testing";

jest.setTimeout(10000);

describe("transactions test", () => {
  // Instantiate emulator and path to Contracts
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../../");
    const port = 8080;
    await init(basePath, { port });
    return emulator.start(port);
  });

  // Stop emulator
  afterEach(async () => {
    return emulator.stop();
  });

  test("create_set", async () => {
    //Deploying contracts used in create_templates
    const serviceAccount = await getServiceAddress();
    await deployContractByName("NonFungibleToken");
    const nftAddrMap = { NonFungibleToken: serviceAccount }
    
    await deployContractByName({name: "Gaia", addressMap: nftAddrMap});
    
    await shallPass(async () => {
      const args = ["Test Set", "Set Description", "https://www.ballerz.xyz/", "image uri", serviceAccount, 0.1];
      return sendTransaction({ name: "create_set", args: args });
    });
  });
});
