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

const getBalanceScrCdc = loadAndReplace('./transactions/scritps/get_balance.cdc')
const getBalanceScr = fcl.cdc(getBalanceScrCdc)

const readListingDetailsScrCdc = loadAndReplace('./transactions/scritps/read_listing_details.cdc')
const readListingDetailsScr = fcl.cdc(readListingDetailsScrCdc)

const readStorefrontIdsScrCdc = loadAndReplace('./transactions/scritps/read_storefront_ids.cdc')
const readStorefrontIdsScr = fcl.cdc(readStorefrontIdsScrCdc)

module.exports = {
    getBalanceScr,
    readListingDetailsScr,
    readStorefrontIdsScr
}