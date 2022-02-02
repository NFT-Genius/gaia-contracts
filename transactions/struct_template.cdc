import Gaia from "../contracts/Gaia.cdc"

transaction(metadata: {String: String}) { 
    prepare(acct: AuthAccount) {
        var tempStruct = Gaia.Template(metadata: metadata)
        let newID = tempStruct.templateID
    }
}