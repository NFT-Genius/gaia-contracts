const fcl = require('@onflow/fcl')
const fs = require('fs')


const replaceContract = (str, contract, replacement) => {
    return str.replace(new RegExp(contract, 'g'), replacement)
}

const loadAndReplace = (file) => {
    let content = fs.readFileSync(file, 'utf8')
    content = replaceContract(content, '"../contracts/Profile.cdc"', '0xProfile')
    content = replaceContract(content, '"../contracts/Gaia.cdc"', '0xGaiaContract')
    content = replaceContract(content, '"../contracts/NFTStorefront.cdc"', '0xNFTStorefront')
    content = replaceContract(content, '"../contracts/FungibleToken.cdc"', '0xFungibleToken')
    content = replaceContract(content, '"../contracts/NonFungibleToken.cdc"', '0xNonFungibleToken')
    content = replaceContract(content, '"../contracts/FlowToken.cdc"', '0xFlowToken')
    
    return content
}

const buyItemTxCdc = loadAndReplace('./transactions/buy_item.cdc')
const buyItemTx = fcl.cdc(buyItemTxCdc)

const cleanupItemTxCdc = loadAndReplace('./transactions/cleanup_item.cdc')
const cleanupItemTx = fcl.cdc(cleanupItemTxCdc)

const removeItemTxCdc = loadAndReplace('./transactions/remove_item.cdc')
const removeItemTx = fcl.cdc(removeItemTxCdc)

const sellItemTxCdc = loadAndReplace('./transactions/sell_item.cdc')
const sellItemTx = fcl.cdc(sellItemTxCdc)

const setupAccountTxCdc = loadAndReplace('./transactions/setup_account.cdc')
const setupAccountTx = fcl.cdc(setupAccountTxCdc)

const setupGaiaCollectionTxCdc = loadAndReplace('./transactions/setup_gaia_collection.cdc')
const setupGaiaCollectionTx = fcl.cdc(setupGaiaCollectionTxCdc)

const createTemplateTxCdc = loadAndReplace('./transactions/create_templates.cdc')
const createTemplateTx = fcl.cdc(createTemplateTxCdc)

const mintNFTTxCdc = loadAndReplace('./transactions/mint_nft.cdc')
const mintNFTTx = fcl.cdc(mintNFTTxCdc)

const createSetTxCdc = loadAndReplace('./transactions/create_set.cdc')
const createSetTx = fcl.cdc(createSetTxCdc)

module.exports = {
    buyItemTx,
    cleanupItemTx,
    removeItemTx,
    sellItemTx,
    setupAccountTx,
    setupGaiaCollectionTx,
    createSetTx,
    createTemplateTx,
    mintNFTTx
}