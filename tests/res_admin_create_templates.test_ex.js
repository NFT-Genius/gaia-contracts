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
    const basePath = path.resolve(__dirname, "../");
    const port = 8080;
    await init(basePath, { port });
    return emulator.start(port);
  });

  // Stop emulator
  afterEach(async () => {
    return emulator.stop();
  });

  test("resources admin create templates", async () => {
    //Deploying contracts used in setup account
    const serviceAccount = await getServiceAddress();
    await deployContractByName("NonFungibleToken");
    const nftAddrMap = { NonFungibleToken: serviceAccount }    
    await deployContractByName({name: "Gaia", addressMap: nftAddrMap});

    await shallPass(async () => {
      //Create Set First and get its ID
      const setArgs = ["Test Set", "Set Description", "https://www.ballerz.xyz/", "image uri", serviceAccount, 0.1];
      const setResult = await sendTransaction({ name: "res_admin_create_set", args: setArgs });

      const tempArgs = [['{"firstName": "Kevin", "lastName": "Durant"}', 
      '{"firstName": "John", "lastName": "Doe"}'], setResult.events[0].data.setID, serviceAccount];
      return await sendTransaction({ name: "res_admin_create_templates", args: tempArgs });
    });
    
  });
});
