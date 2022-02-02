import path from "path";
import { 
  emulator, 
  init, 
  shallPass,
  sendTransaction,
  deployContractByName,
  getServiceAddress,
  getAccountAddress,
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

  test("struct set data add account", async () => {
    //Deploying contracts used in setup account
    const serviceAccount = await getServiceAddress();
    await deployContractByName("NonFungibleToken");
    const nftAddrMap = { NonFungibleToken: serviceAccount }    
    await deployContractByName({name: "Gaia", addressMap: nftAddrMap});

    const AliceAcc = await getAccountAddress("Alice");
    console.log("Account Address for Alice is " + AliceAcc);

    await shallPass(async () => {
      const setArgs = ["Test Set Data Struct", "Set Description", "https://www.ballerz.xyz/", "image uri", 
      serviceAccount, 0.1, AliceAcc];
      return await sendTransaction({ name: "struct_set_data_add_account", args: setArgs });
    });
    
  });
});
