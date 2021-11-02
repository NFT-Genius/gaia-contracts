import * as t from "@onflow/types";
import { getManagerAddress } from "./manager";
import { executeScript } from "./interaction";
import { defaultsByName } from "./file";

import registry from "./generated";

/**
 * Returns address of the account where contract specified by name is currently deployed
 * @param {string} name - name of the account to look for
 * @param {boolean} [useDefaults=false] - whether we shall look into default addressed first
 * @returns {Promise<string>}
 */
export const getContractAddress = async (name, useDefaults = false) => {
  // TODO: Maybe try to automatically deploy contract? 🤔

  if (useDefaults) {
    const defaultContract = defaultsByName[name];
    if (defaultContract !== undefined) {
      return defaultContract;
    }
  }

  const managerAddress = await getManagerAddress();

  const addressMap = {
    FlowManager: managerAddress,
  };

  let contractAddress;
  try {
    const code = await registry.scripts.getContractAddressTemplate(addressMap);
    const args = [
      [name, t.String],
      [managerAddress, t.Address],
    ];
    contractAddress = await executeScript({
      code,
      args,
      service: true,
    });
  } catch (e) {
    console.error("failed to get account address:", e);
  }

  return contractAddress;
};
