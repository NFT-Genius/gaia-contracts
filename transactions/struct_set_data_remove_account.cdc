import Gaia from "../contracts/Gaia.cdc"

transaction(name: String, description: String, website: String, imageURI: String, creator: Address, 
marketFee: UFix64, allowedAccount: Address) {
    prepare(acct: AuthAccount) {
        var nextSetID = Gaia.nextSetID
        var setDataStruct = Gaia.SetData(name: name, description: description, 
        website: website, imageURI: imageURI, creator: creator, marketFee: marketFee)

        setDataStruct.addAllowedAccount(account: allowedAccount)
        setDataStruct.removeAllowedAccount(account: allowedAccount)
    }
}