import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import Gaia from "../contracts/Gaia.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64, setID: UInt64, marketAddress: Address) {
    let marketFlowReceiver: Capability<&{FungibleToken.Receiver}>
    let sellerFlowReceiver: Capability<&{FungibleToken.Receiver}>
    let GaiaProvider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront
    let marketFee: UFix64

    prepare(acct: AuthAccount) {

        // We need a provider capability, but one is not provided by default so we create one if needed.
        let GaiaCollectionProviderPrivatePath = /private/GaiaCollectionProviderForNFTStorefront

        self.sellerFlowReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        assert(self.sellerFlowReceiver.borrow() != nil, message: "Missing or mis-typed FlowToken receiver")

        self.marketFlowReceiver = getAccount(marketAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        assert(self.marketFlowReceiver.borrow() != nil, message: "Missing or mis-typed FlowToken receiver")
        
        if !acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath)!.check() {
            acct.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath, target: Gaia.CollectionStoragePath)
        }
            
        self.marketFee = Gaia.getSetMarketFee(setID: setID)!

        self.GaiaProvider = acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath)
        assert(self.GaiaProvider.borrow() != nil, message: "Missing or mis-typed Gaia.Collection provider")

        self.storefront = acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        let marketCutAmount = saleItemPrice * self.marketFee
        let marketSaleCut = NFTStorefront.SaleCut(
            receiver: self.marketFlowReceiver,
            amount: marketCutAmount
        )
        let sellerSaleCut = NFTStorefront.SaleCut(
            receiver: self.sellerFlowReceiver,
            amount: saleItemPrice - marketCutAmount
        )
        
        self.storefront.createListing(
            nftProviderCapability: self.GaiaProvider,
            nftType: Type<@Gaia.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: [sellerSaleCut, marketSaleCut]
        )
    }
}
