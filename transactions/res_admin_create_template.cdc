import Gaia from "../contracts/Gaia.cdc"

transaction(metadata: {String: String}) {
    prepare(acct: AuthAccount) {
        let admin = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin) ?? panic("No admin resource in storage")
        admin.createTemplate(metadata: metadata)
    }
}