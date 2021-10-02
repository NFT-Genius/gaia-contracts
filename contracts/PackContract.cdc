import FungibleToken from 0x9a0766d93b6608b7
import Gaia from 0xc523a8bbf10fc4a3
pub contract PackContract {

  // Events
  pub event ContractInitialized()
  pub event PackOpened(id: UInt32, buyer: Address)

  // Named Paths
  pub let StoragePath: StoragePath
  pub let PublicPath: PublicPath

  // Variables
  pub var nextPackId: UInt32

  // ----------------------------------------------------------------
  // Structs

  // Royalty fees given on pack sale, ie. to Artist. (Rest goes to stored Receiver)
  pub struct Royalty {
    pub let receiver:Capability<&{FungibleToken.Receiver}> 
    pub let cut: UFix64

    init(receiver:Capability<&{FungibleToken.Receiver}>, cut: UFix64 ){
      self.receiver = receiver
      self.cut = cut
    }
  }

  pub struct Pack {
    pub let id: UInt32
    pub(set) var price: UFix64
    pub(set) var available: UInt32
    pub(set) var templates: [UInt64]
    pub let royalties: {String: Royalty}

    init(price: UFix64, templates: [UInt64],  available: UInt32, royalties: {String: Royalty}) {
      self.price = price
      self.templates = templates
      self.available = available
      self.royalties = royalties
      self.id = PackContract.nextPackId
      PackContract.nextPackId = PackContract.nextPackId + (1 as UInt32)
    }

    pub fun setPrice(price: UFix64) {
      self.price = price
    }

    pub fun removePack() {
      if (self.available == (0 as UInt32)) { panic("No packs left!") }
      self.available = self.available - (1 as UInt32)
    }
  }

  // ----------------------------------------------------------------
  // Resources Interfaces

  pub resource interface Public {
    pub fun purchase(packId: UInt32, buyerAddress: Address, paymentTokens: @FungibleToken.Vault)
    pub fun getPackIds(): [UInt32]
    pub fun getAvailable(packId: UInt32): UInt32
    pub fun getPrice(packId: UInt32): UFix64
  }

  // ----------------------------------------------------------------
  // Resources

  pub resource Market: Public {
    access(self) var paymentReceiver: Capability<&{FungibleToken.Receiver}>?
    access(self) var packs: {UInt32: Pack}

    init() {
      self.paymentReceiver = nil
      self.packs = {}
    }

    // Public Functions

    pub fun purchase(packId: UInt32, buyerAddress: Address, paymentTokens: @FungibleToken.Vault) {
      let pack = self.packs[packId] ?? panic("Pack does not exist.")
      if (pack.available == (0 as UInt32)) { panic("No packs available for sale.") }
      if (paymentTokens.balance < pack.price) { panic("Insuficient balance.") }
      let paymentReceiver = self.paymentReceiver ?? panic("Payment Receiver must be setup.")
      let paymentReceiverRef = paymentReceiver.borrow() ?? panic("Payment Receiver capability failed.")

      // Subtract royalty fees
      for key in pack.royalties.keys {
        let royalty = pack.royalties[key]!
        let amount = pack.price * royalty.cut
        if let receiver = royalty.receiver.borrow() {
          receiver.deposit(from: <- paymentTokens.withdraw(amount: amount) )
        }
      }

      // Deposit $$ tokens in paymentReceiver
      paymentReceiverRef.deposit(from: <- paymentTokens)

      // Decrement available packs
      self.packs[packId]!.removePack()

      emit PackOpened(id: packId, buyer: buyerAddress)
    }

    pub fun getPackIds(): [UInt32] {
      return self.packs.keys
    }

    pub fun getAvailable(packId: UInt32): UInt32 {
      let pack = self.packs[packId] ?? panic("Pack does not exist!")
      return pack.available
    }

    pub fun getPrice(packId: UInt32): UFix64 {
      let pack = self.packs[packId] ?? panic("Pack does not exist!")
      return pack.price
    }
    pub fun getPackTemplates(packId: UInt32): [UInt64] {
      let pack = self.packs[packId] ?? panic("Pack does not exist!")
      return pack.templates
    }

    // Owner Functions

    pub fun createPack(price: UFix64, templates:[UInt64], available: UInt32, royalties: {String: Royalty}) {
      let pack = Pack(price: price, templates: templates, available: available, royalties: royalties)
      self.packs[pack.id] = pack
    }

    pub fun setPrice(packId: UInt32, price: UFix64) {
      self.packs[packId]!.setPrice(price: price)
    }

    pub fun cancelPack(packId: UInt32) {
      pre { self.packs[packId] != nil: "Pack does not exist!" }
      self.packs.remove(key: packId)
      self.packs[packId] = nil
    }

    pub fun setPaymentReceiver(_ paymentReceiver: Capability<&{FungibleToken.Receiver}>) {
      pre { paymentReceiver.borrow() != nil: "Payment Receiver Capability is invalid!" }
      self.paymentReceiver = paymentReceiver
    }

    pub fun createNewPackMarket(): @Market {
      return <-create Market()
    }
  }

  // ----------------------------------------------------------------
  // Contract Functions

  // ----------------------------------------------------------------
  init() {
    self.StoragePath = /storage/PackStorage1
    self.PublicPath = /public/PackStorage1
    self.nextPackId = 1

    // Create market and public capability for this account.
    // Warning, sets up with NO payment receiver. It must be set before use.
    let market <- create Market()
    
    // Save Market in account
    self.account.save<@PackContract.Market>(<-market, to: self.StoragePath)

    // Create public capability for purchasing
    self.account.link<&{PackContract.Public}>(self.PublicPath, target: self.StoragePath)

    emit ContractInitialized()
  }
}

 