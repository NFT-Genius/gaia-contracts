import { set } from "./config";
import { config } from "@onflow/config";

/**
 * Inits framework variables, storing private key of service account and base path
 * where Cadence files are stored.
 * @param {string} basePath - path to the folder with Cadence files to be tested.
 * @param {number} [props.port] - port to use for accessAPI
 * @param {number} [props.pkey] - private key to use for service account in case of collisions
 */
export const init = async (basePath, props = {}) => {
  const { port = 8080 } = props;
  const { pkey = "5923fba05d2ab3406eff03d50ee7557b8902490ba3f2ae82936bb457dc88aefb" } = props;

  set("PRIVATE_KEY", process.env.PK, "accounts/emulator-account/key", pkey);
  set(
    "SERVICE_ADDRESS",
    process.env.SERVICE_ADDRESS,
    "accounts/emulator-account/address",
    "f8d6e0586b0a20c7",
  );
  set("BASE_PATH", process.env.BASE_PATH, "testing/paths", basePath);

  config().put("accessNode.api", `http://localhost:${port}`);
};
