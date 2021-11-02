import path from "path";
import emulator from "../src/emulator";
import init from "../src/init";
import deployContractByName from "../src/deploy-code";
import getContractAddress from "../src/contract";
import getServiceAddress from "../src/manager";

jest.setTimeout(10000);

describe("deploying all contracts", () => {
  // Instantiate emulator and path to Contracts
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "./contracts");
    const port = 8080;
    await init(basePath, { port });
    return emulator.start(port);
  });

  // Stop emulator
  afterEach(async () => {
    return emulator.stop();
  });

  test("NonFungibleToken contract deploy", async () => {
    const name = "NonFungibleToken";
    await deployContractByName({ name });
    const address = await getContractAddress(name);
    const serviceAccount = await getServiceAddress();
    expect(address).toBe(serviceAccount);
  });

  // test("Gaia contract deploy", async () => {
  //   const name = "Gaia";
  //   await deployContractByName({ name });
  //   const address = await getContractAddress(name);
  //   const serviceAccount = await getServiceAddress();
  //   expect(address).toBe(serviceAccount);
  // });

  // test("Profile contract deploy", async () => {
  //   const name = "Profile";
  //   await deployContractByName({ name });
  //   const address = await getContractAddress(name);
  //   const serviceAccount = await getServiceAddress();
  //   expect(address).toBe(serviceAccount);
  // });

  // test("NFTStorefront contract deploy", async () => {
  //   const name = "NFTStorefront";
  //   await deployContractByName({ name });
  //   const address = await getContractAddress(name);
  //   const serviceAccount = await getServiceAddress();
  //   expect(address).toBe(serviceAccount);
  // });
});
