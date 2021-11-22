import Gaia from "../../contracts/Gaia.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

pub fun main(address: Address): Bool {
  return getAccount(address)
    .getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
    .check()
}