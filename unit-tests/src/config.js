import { flowConfig } from "@onflow/fcl-config";
import { config } from "@onflow/config";

/**
 * Get value from provided scope and path.
 * @param scope - scope value.
 * @param path - value path in config (flow.json) file.
 * @param fallback - fallback value.
 * @returns {*} - value at specified scope and path.
 */
export const get = (scope, path, fallback) => {
  if (typeof path === "string") return get(scope, path.split("/"), fallback);
  if (!path.length) return scope;
  try {
    const [head, ...rest] = path;
    return get(scope[head], rest, fallback);
  } catch (_error) {
    return fallback;
  }
};

/**
 * Set globally available config value.
 * @param {string} key - key to be used to access stored value.
 * @param {string} env - value key in the environment (for example .env file).
 * @param {string} conf - value path in config (flow.json) file.
 * @param fallback - fallback value to be used if env and conf are absent.
 */
export const set = (key, env, conf, fallback) => {
  let value = get(flowConfig(), conf, fallback);
  if (!value) {
    value = fallback;
  }
  config().put(key, value);
};

/**
 * Returns config value at specified key.
 * @param key - key to the value.
 * @returns {Promise<*>} - value at specified key.
 */
export const getConfigValue = async (key) => {
  return config().get(key);
};
