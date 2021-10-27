"use strict";
const path = require("path");

let testPackage = require("flow-js-testing");
const {
  createAccount,
  deployContract,
  getTemplate,
  executeScript,
} = testPackage;

const getContractTemplate = (contractName, addressMap) => {
  const resolvedPath = path.resolve(`./contracts/${contractName}.cdc`);
  return getTemplate(resolvedPath, addressMap);
};

const main = async () => {
  const contractAddress = await createAccount();
  const contractCode = getContractTemplate("NonFungibleToken");
  console.log({ contractCode });

  try {
    const deployTx = await deployContract(contractAddress, contractCode);
  } catch (error) {
    console.log("Error Deploying Contract:");
    console.log(error);
  }

  console.log({ contractAddress });
};

main();
