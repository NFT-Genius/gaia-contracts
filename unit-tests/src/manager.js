import { executeScript, sendTransaction } from "./interaction";
import { config } from "@onflow/config";
import { withPrefix } from "./address";
import { hexContract } from "./deploy-code";
import registry from "./generated";

export const initManager = async () => {
  const code = await registry.transactions.initManagerTemplate();
  const contractCode = await registry.contracts.FlowManagerTemplate();
  const hexedContract = hexContract(contractCode);
  const args = [hexedContract];

  await sendTransaction({
    code,
    args,
    service: true,
  });
};

export const getServiceAddress = async () => {
  return withPrefix(await config().get("SERVICE_ADDRESS"));
};

export const getManagerAddress = async () => {
  const serviceAddress = await getServiceAddress();

  const addressMap = {
    FlowManager: serviceAddress,
  };

  const code = await registry.scripts.checkManagerTemplate(addressMap);

  try {
    await executeScript({
      code,
      service: true,
    });
  } catch (e) {
    await initManager();
  }

  return getServiceAddress();
};

// TODO: replace method above after Cadence will allow to get contracts list on PublicAccount
/*
export const getManagerAddress = async () => {
  const serviceAddress = await getServiceAddress();

  const code = `
    pub fun main(address: Address):Bool {
      return getAccount(address).contracts.get("FlowManager") != null
    }
  `;
  const result = await executeScript({ code, args: [serviceAddress] });

  if (!result) {
    await initManager();
  }

  return serviceAddress;
};
 */

export const getBlockOffset = async () => {
  const FlowManager = await getManagerAddress();
  const code = await registry.scripts.getBlockOffsetTemplate({ FlowManager });
  return executeScript({ code });
};

export const setBlockOffset = async (offset) => {
  const FlowManager = await getManagerAddress();

  const args = [offset];
  const code = await registry.transactions.setBlockOffsetTemplate({ FlowManager });
  const payer = [FlowManager];

  return sendTransaction({ code, args, payer });
};
