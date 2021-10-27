import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Gaia from "../../contracts/Gaia.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

pub struct PurchaseData {
    pub let id: UInt64
    pub let name: String?
    pub let amount: UFix64
    pub let description: String?
    pub let imageURL: String?
    
    init(id: UInt64, name: String?, amount: UFix64, description: String?, imageURL: String?) {
        self.id = id
        self.name = name
        self.amount = amount
        self.description = description
        self.imageURL = imageURL
    }
}
pub fun main(address: Address, listingResourceID: UInt64): PurchaseData {
    let account = getAccount(address)
    let marketCollectionRef = account
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow market collection from address")
        
    let gaiaCollectionRef = account
        .getCapability(Gaia.CollectionPublicPath)
        .borrow<&{Gaia.CollectionPublic}>()
        ?? panic("Could not borrow Gaia collection from address")
    
    let saleItem = marketCollectionRef.borrowListing(listingResourceID: listingResourceID)
        ?? panic("No item with that ID")

    let listingDetails = saleItem.getDetails()!
    let gaiaNFT = gaiaCollectionRef.borrowGaiaNFT(id: listingDetails.nftID)!
    let setData = Gaia.getSetInfo(setID: gaiaNFT.data.setID)!
    let templateMetadata = Gaia.getTemplateMetaData(templateID: gaiaNFT.data.templateID)
    let title = Gaia.getTemplateMetaDataByField(templateID: gaiaNFT.data.templateID, field: "title")
    let imageURL = Gaia.getTemplateMetaDataByField(templateID: gaiaNFT.data.templateID, field: "img")
    let description = Gaia.getTemplateMetaDataByField(templateID: gaiaNFT.data.templateID, field: "description")
    
    let purchaseData = PurchaseData(
        id: listingResourceID,
        name: title,
        amount: listingDetails.salePrice,
        description: description,
        imageURL: imageURL
    )
    return purchaseData
}