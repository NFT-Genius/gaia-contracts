import NFTStorefront from "../../contracts/NFTStorefront.cdc"

pub fun main(address: Address): Bool {
    return getAccount(address)
    .getCapability<&{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
    .check()
}