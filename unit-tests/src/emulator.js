const { spawn } = require("child_process");

const DEFAULT_HTTP_PORT = 8080;
const DEFAULT_GRPC_PORT = 3569;

export class Emulator {
  /* Create an emulator instance*/
  constructor() {
    this.initialized = false;
    this.logging = false;
    this.logProcessor = (item) => item;
  }

  /* Set logging flag */
  setLogging(logging) {
    this.logging = logging;
  }

  /* Log message with a specific type 
   * @param {*} message - message to put into log output
   * @param {"log"|"error"} type - type of the message to output
   */
  log(message, type = "log") {
    this.logging && console[type](message);
  }

  extractKeyValue(str) {
    const [key, value] = str.split("=");
    if (value.includes("LOG")) {
      return { key, value: value.replace(`"\x1b[1;34m`, `"\x1b[1[34m`) };
    }
    return { key, value };
  }

  parseDataBuffer(data) {
    const match = data.toString().match(/((\w+=\w+)|(\w+=".*?"))/g);
    if (match) {
      const pairs = match.map((item) => item.replace(/"/g, ""));
      return pairs.reduce((acc, pair) => {
        const { key, value } = this.extractKeyValue(pair);
        acc[key] = value;
        return acc;
      }, {});
    }
    return {};
  }

  /* Start emulator
   * @param {number} port - port to use for accessApi
   * @param {boolean} logging - whether logs shall be printed
   */
  async start(port = DEFAULT_HTTP_PORT, logging = false) {
    const offset = port - DEFAULT_HTTP_PORT;
    let grpc = DEFAULT_GRPC_PORT + offset;

    this.logging = logging;
    this.filters = [];
    this.process = spawn("flow", ["emulator", "-v", "--http-port", port, "--port", grpc]);
    this.logProcessor = (item) => item;

    return new Promise((resolve, reject) => {
      this.process.stdout.on("data", (data) => {
        if (this.filters.length > 0) {
          for (let i = 0; i < this.filters.length; i++) {
            const filter = this.filters[i];
            if (data.includes(`${filter}`)) {
              this.log(`LOG: ${data}`);
              break;
            }
          }
        } else {
          this.log(`LOG: ${data}`);
        }
        if (data.includes("Starting HTTP server")) {
          this.log("EMULATOR IS UP! Listening for events!");
          this.initialized = true;
          resolve(true);
        }
      });

      this.process.stderr.on("data", (data) => {
        this.log(`ERROR: ${data}`, "error");
        this.initialized = false;
        reject();
      });

      this.process.on("close", (code) => {
        this.log(`emulator exited with code ${code}`);
        this.initialized = false;
        resolve(false);
      });
    });
  }

  /* Clear all log filters */
  clearFilters() {
    this.filters = [];
  }

  /* Remove specific log filter >> @param type (debug|info|warning) */
  removeFilter(type) {
    this.filters = this.filters((item) => item !== type);
  }

  /* Add log filter >> @param type (debug|info|warning) */
  addFilter(type) {
    if (!this.filters.includes(type)) {
      this.filters.push(type);
    }
  }

  /* Stop emulator */
  async stop() {
    return new Promise((resolve) => {
      this.process.kill();
      setTimeout(() => {
        this.initialized = false;
        resolve(false);
      }, 50);
    });
  }
}

export default new Emulator();