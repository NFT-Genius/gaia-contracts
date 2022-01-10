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

  test("setup account", async () => {
    //Deploying contracts used in setup account
    await deployContractByName("Profile");

    const serviceAccount = await getServiceAddress();
    await deployContractByName("NonFungibleToken");
    const nftAddrMap = { NonFungibleToken: serviceAccount }
    
    await deployContractByName("FungibleToken");
    const ftAddrMap = { FungibleToken: serviceAccount }

    await deployContractByName({name: "NFTStorefront", addressMap: nftAddrMap, ftAddrMap});
    await deployContractByName({name: "DapperUtilityCoin", addressMap: ftAddrMap});
    await deployContractByName({name: "Gaia", addressMap: nftAddrMap});

    await shallPass(async () => {
      const res = await sendTransaction({ name: "setup_account" });
      console.log(res.events[0]);
      return res;
    });
    
  });
});
