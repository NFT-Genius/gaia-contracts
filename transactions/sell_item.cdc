import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import Gaia from "../contracts/Gaia.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {
    let ducReceiver: Capability<&{FungibleToken.Receiver}>
    let GaiaProvider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(acct: AuthAccount) {

        // We need a provider capability, but one is not provided by default so we create one if needed.
        let GaiaCollectionProviderPrivatePath = /private/GaiaCollectionProviderForNFTStorefront

        self.ducReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        assert(self.ducReceiver.borrow() != nil, message: "Missing or mis-typed DapperUtilityCoin receiver")
        
        if !acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath)!.check() {
            acct.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath, target: Gaia.CollectionStoragePath)
        }

        self.GaiaProvider = acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath)
        assert(self.GaiaProvider.borrow() != nil, message: "Missing or mis-typed Gaia.Collection provider")

        self.storefront = acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.ducReceiver,
            amount: saleItemPrice
        )
        self.storefront.createListing(
            nftProviderCapability: self.GaiaProvider,
            nftType: Type<@Gaia.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@DapperUtilityCoin.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
 