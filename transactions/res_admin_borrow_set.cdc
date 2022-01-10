import Gaia from "../contracts/Gaia.cdc"

transaction(setID: UInt64, recipientAddr: Address) {
    let adminRef: &Gaia.Admin

    prepare(acct: AuthAccount) {
        self.adminRef = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)!
    }

    execute {
        let setRef = self.adminRef.borrowSet(setID: setID, authorizedAccount: recipientAddr)
    }
}