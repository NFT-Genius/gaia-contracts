/* eslint-disable no-undef */
import path from 'path';
import {
  emulator,
  init,
  deployContractByName,
  getContractAddress,
  getServiceAddress
} from 'flow-js-testing';

jest.setTimeout(10000);

describe('deploying all contracts', () => {
  // Instantiate emulator and path to Contracts
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../');
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
    await deployContractByName(name);
    const address = await getContractAddress(name);
    const serviceAccount = await getServiceAddress();
    expect(address).toBe(serviceAccount);
  });

  test("Gaia contract deploy", async () => {
    const serviceAccount = await getServiceAddress();
    
    //Deploy the "Import NonFungibleToken" Contract
    await deployContractByName("NonFungibleToken");
    const nftAddrMap = { NonFungibleToken: serviceAccount }

    //Deploy Main "Gaia" Contract
    const name = "Gaia";
    await deployContractByName({name: name, addressMap: nftAddrMap});
    const address = await getContractAddress(name);
    expect(address).toBe(serviceAccount);
  });
  
  test("Profile contract deploy", async () => {
    const name = "Profile";
    await deployContractByName(name);
    const address = await getContractAddress(name);
    const serviceAccount = await getServiceAddress();
    expect(address).toBe(serviceAccount);
  });

  test("NFTStorefront contract deploy", async () => {
    const serviceAccount = await getServiceAddress();
    
    //Deploy the "Import NonFungibleToken" Contract
    await deployContractByName("NonFungibleToken");
    const nftAddrMap = { NonFungibleToken: serviceAccount }

    //Deploy the "Import FungibleToken" Contract
    await deployContractByName("FungibleToken");
    const ftAddrMap = { FungibleToken: serviceAccount }

    //Deploy Main "NFTStorefront" Contract
    const name = "NFTStorefront";
    await deployContractByName({name: name, addressMap: nftAddrMap, ftAddrMap});
    const address = await getContractAddress(name);
    expect(address).toBe(serviceAccount);
  });

  test("Dapper Utility Coin contract deploy", async () => {
    const name = "DapperUtilityCoin";
    await deployContractByName(name);
    const address = await getContractAddress(name);
    const serviceAccount = await getServiceAddress();
    expect(address).toBe(serviceAccount);
  });
});