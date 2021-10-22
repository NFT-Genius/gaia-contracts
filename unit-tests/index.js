const fcl = require("@onflow/fcl");
const { ec: EC } = require("elliptic");
const { SHA3 } = require("sha3");
const t = require("@onflow/types");

require("dotenv").config();

const ec = new EC("p256");

const {
  buyItemTx,
  cleanupItemTx,
  removeItemTx,
  sellItemTx,
  setupAccountTx,
  setupGaiaCollectionTx,
  createTemplateTx,
  createSetTx,
  mintNFTTx
} = require("./src/transactions")

const ACCESS_NODE = process.env.ACCESS_NODE
const GAIA_CONTRACT = process.env.GAIA_CONTRACT

const MINTER_ADDRESS = process.env.MINTER_ADDRESS
const MINTER_PRIVATE_KEY = process.env.MINTER_PRIVATE_KEY
const MINTER_ACCOUNT_INDEX = process.env.MINTER_ACCOUNT_INDEX

const STOREFRONT_ADDRESS = process.env.STOREFRONT_ADDRESS
const STOREFRONT_PRIVATE_KEY = process.env.STOREFRONT_PRIVATE_KEY
const STOREFRONT_ACCOUNT_INDEX = process.env.STOREFRONT_ACCOUNT_INDEX 

const STOREFRONT_CONTRACT = process.env.STOREFRONT_CONTRACT;
const PROFILE_CONTRACT = process.env.PROFILE_CONTRACT;
const NFT_INTERFACE = process.env.NFT_INTERFACE;
const TOKEN_INTERFACE = process.env.TOKEN_INTERFACE;
const FLOW_TOKEN_INTERFACE = process.env.FLOW_TOKEN_INTERFACE;

const DUC_CONTRACT = process.env.DUC_CONTRACT;

fcl
  .config()
  .put("accessNode.api", ACCESS_NODE)
  .put("0xGaiaContract", GAIA_CONTRACT)
  .put("0xNFTStorefront", STOREFRONT_CONTRACT)
  .put("0xFungibleToken", TOKEN_INTERFACE)
  .put("0xNonFungibleToken", NFT_INTERFACE)
  .put('0xFlowToken', FLOW_TOKEN_INTERFACE)
  .put("0xProfile", PROFILE_CONTRACT)
  .put('0xDuc', DUC_CONTRACT);

  // import FungibleToken from 0xee82856bf20e2aa6
  // import NonFungibleToken from 0xNonFungibleToken
  // import FlowToken from 0x0ae53cb6e3f42a79
  // import Gaia from 0xGaiaContract
  // import NFTStorefront from 0xNFTStorefront

// ####### UTILS #######
const signWithKey = (privateKey, msg) => {
  const key = ec.keyFromPrivate(Buffer.from(privateKey, "hex"));
  const sig = key.sign(hashMsg(msg));
  const n = 32;
  const r = sig.r.toArrayLike(Buffer, "be", n);
  const s = sig.s.toArrayLike(Buffer, "be", n);
  return Buffer.concat([r, s]).toString("hex");
};

const hashMsg = (msg) => {
  const sha = new SHA3(256);
  sha.update(Buffer.from(msg, "hex"));
  return sha.digest();
};

const authorizeMinter = (accAddr, accIndex, accPK) => {
  return async (account) => {
    const sign = signWithKey;
    const pk = accPK;

    return {
      ...account,
      tempId: `${accAddr}-${accIndex}`,
      addr: fcl.sansPrefix(accAddr),
      keyId: Number(accIndex),
      signingFunction: (signable) => {
        return {
          addr: fcl.withPrefix(accAddr),
          keyId: Number(accIndex),
          signature: sign(pk, signable.message),
        };
      },
    };
  };
};

const templateData = [Object.entries({
  "name": "Augue est commodo.",
  "image": "https://source.unsplash.com/user/erondu/298x336",
  "hair": "mediumaquamarine",
  "skin": "darkgreen"
})
.map(([key, value]) => ({
  key,
  value
}))];

async function executeTransaction(tx, accAddr, accIndex, accPK, args = []) {
    try {
        const txId = await fcl
            .send([
                fcl.transaction(tx),
                fcl.args(args),
                fcl.payer(authorizeMinter(accAddr, accIndex, accPK)), // current user is responsible for paying for the transaction
                fcl.proposer(authorizeMinter(accAddr, accIndex, accPK)), // current user acting as the nonce
                fcl.authorizations([authorizeMinter(accAddr, accIndex, accPK)]), // current user will be first AuthAccount
                fcl.limit(500), // set the compute limit
            ]).then(fcl.decode)
        console.log(`Transaction ID: ${txId}`);
        return fcl.tx(txId).onceSealed();
    } catch (err) {
        console.error(err);
    }
}

const STEPS = {
  SETUP_ACCOUNT: 'SETUP_ACCOUNT',
  SETUP_GAIA_COLLECTION: 'SETUP_GAIA_COLLECTION',
  CREATE_SET: 'CREATE_SET',
  CREATE_TEMPLATE: 'CREATE_TEMPLATE',
  BUY_ITEM: 'BUY_ITEM',
  SELL_ITEM: 'SELL_ITEM',
  CLEANUP_ITEM: 'CLEANUP_ITEM',
  REMOVE_ITEM: 'REMOVE_ITEM',
  MINT_NFT: 'MINT_NFT',
}

const executeFlow = async ({ steps }) => {
  let assetID
  let setID
  let templateID
  let listingResourceID

  if (steps.includes(STEPS.SETUP_ACCOUNT)) {
    await executeTransaction(setupAccountTx, STOREFRONT_ADDRESS, STOREFRONT_ACCOUNT_INDEX, STOREFRONT_PRIVATE_KEY);
  }
  if (steps.includes(STEPS.SETUP_GAIA_COLLECTION)) {
    // Setup Storefront Account
    // Prepare Storefront Account to receive Gaia NFTs
    await executeTransaction(setupGaiaCollectionTx, STOREFRONT_ADDRESS, STOREFRONT_ACCOUNT_INDEX, STOREFRONT_PRIVATE_KEY);
  }
  if (steps.includes(STEPS.CREATE_SET)) {
    // Create Collection
    const collectionTx = await executeTransaction(createSetTx, MINTER_ADDRESS, MINTER_ACCOUNT_INDEX, MINTER_PRIVATE_KEY, [
      fcl.arg('Ballerz', t.String),
      fcl.arg('Ballerz collection', t.String),
      fcl.arg('https://ongaia.com/collections/ballerz', t.String),
      fcl.arg('https://bit.ly/image.png', t.String),
      fcl.arg(STOREFRONT_ADDRESS, t.Address),
      fcl.arg('0.05', t.UFix64)
    ])
    setID = collectionTx.events[0].data.setID;
    console.log(`Set ID: ${setID}`);
  }
  
  if (steps.includes(STEPS.CREATE_TEMPLATE)) {
    // Create Template
    const templateCreated = await executeTransaction(createTemplateTx, MINTER_ADDRESS, MINTER_ACCOUNT_INDEX, MINTER_PRIVATE_KEY, [
      fcl.arg(templateData, t.Array(t.Dictionary({ key: t.String, value: t.String }))),
      fcl.arg(setID, t.UInt64),
      fcl.arg(STOREFRONT_ADDRESS, t.Address)
    ])
    templateID = templateCreated.events[1].data.templateID;
    console.log(`Template ID: ${templateID}`);
  }

  if (steps.includes(STEPS.MINT_NFT)) {
    // Mint NFTs to Storefront Account
    const mintTemplate = await executeTransaction(mintNFTTx, MINTER_ADDRESS, MINTER_ACCOUNT_INDEX, MINTER_PRIVATE_KEY, [
      fcl.arg(parseInt(setID, 10), t.UInt64),
      fcl.arg(parseInt(templateID, 10), t.UInt64),
      fcl.arg(STOREFRONT_ADDRESS, t.Address)
    ])
    assetID = mintTemplate.events[0].data.assetID;
    console.log(`Asset ID: ${assetID}`);
  }

  if (steps.includes(STEPS.SELL_ITEM)) {
    const sellItem = await executeTransaction(sellItemTx, STOREFRONT_ADDRESS, STOREFRONT_ACCOUNT_INDEX, STOREFRONT_PRIVATE_KEY, [
      fcl.arg(assetID, t.UInt64),
      fcl.arg('200.5', t.UFix64)
    ])
  
    listingResourceID = sellItem.events[0].data.listingResourceID;
  }

  if (steps.includes(STEPS.BUY_ITEM)) {
    const buyItem = await executeTransaction(buyItemTx, MINTER_ADDRESS, MINTER_ACCOUNT_INDEX, MINTER_PRIVATE_KEY, [
      fcl.arg(listingResourceID, t.UInt64),
      fcl.arg(STOREFRONT_ADDRESS, t.Address)
    ])
    console.log(buyItem.events[0].data)
  }
}

executeFlow({steps: [
  STEPS.SETUP_ACCOUNT,
  STEPS.SETUP_GAIA_COLLECTION,
  STEPS.CREATE_SET,
  STEPS.CREATE_TEMPLATE,
  STEPS.MINT_NFT,
  STEPS.SELL_ITEM,
  STEPS.BUY_ITEM, 
]})

// Deploy Contracts

// Marketplace Operations

// List item for sale
// Listen for events
// Buy item
 