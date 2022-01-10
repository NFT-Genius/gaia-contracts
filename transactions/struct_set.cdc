import Gaia from "../contracts/Gaia.cdc"

transaction(name: String, description: String, website: String, imageURI: String, creator: Address, marketFee: UFix64) {
    prepare(acct: AuthAccount) {
        var nextSetID = Gaia.nextSetID
        let setStruct <- create Gaia.Set(name: name, description: description, 
        website: website, imageURI: imageURI, creator: creator, marketFee: marketFee)
    }
}