import Gaia from "../contracts/Gaia.cdc"

transaction(templates: [{String: String}], setID: UInt64, authorizedAccount: Address) {
    prepare(acct: AuthAccount) {
        let admin = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin) ?? panic("No admin resource in storage")        
        admin.createTemplates(templates: templates, setID: setID, authorizedAccount: authorizedAccount)
    }
}