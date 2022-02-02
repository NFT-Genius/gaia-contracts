# Gaia Contracts

Public repository of Gaia marketplace (<https://ongaia.com>) smart contracts.

![GitHub](https://img.shields.io/github/license/NFT-Genius/gaia-contracts)
![GitHub package.json version](https://img.shields.io/github/package-json/v/NFT-Genius/gaia-contracts?color=blue)

## Getting Started

### Create Account

A testnet account is required to deploy these contracts and to get started you need to generate a key pair, run the following command on your terminal:

```bash
flow keys generate -n testnet
```

This command will produce a result similar to the following:

```
🔴️ Store private key safely and don't share with anyone!
Private Key 	 ea90606c5177d7afc01530d78d1daffe89bdd5c99117159eb8e8cff3d95fccfb
Public Key 	 7dd0a01b45a14584bff3d993f7a70a8db8bb46e4b3a9e4fbae62b6b071cfeb1eaf7c1f19a42f5c33f9f66186d0375191a2360134ebfa3a8c30a08173dd8ce0f5
```

> __WARNING:__ Save the private key somewhere safe and don't share it with anyone.

Copy the public key and paste it into the [Flow Account Creation](https://testnet-faucet.onflow.org/) website.

Follow the instructions to create a new account and save the account address.

Now you can deploy the contracts using the account address and the private key to sing the transactions.

### Seed Data

Use the seed script to add example data to the contract:

```bash
## List available options
node -r esm ./src/seed.js --help
```

### Deploy Contracts

Make sure the flow.json file is correctly configured.

> __INFO:__ You can view the options available in the official documentation at <https://docs.onflow.org/flow-cli/configuration/>

Under testnet object must have the contracts as value of account object key

With everything set up, run the following commands to submit or update contracts:

__To deploy__

```bash
yarn testnet:deploy
```

__To update__

```bash
yarn testnet:update
```

> __NOTE:__ Updates only works for non-initialized parts of the contract.

## Unit Tests

> __Important:__ To make the unit tests work, you need to update values on the emulator-account section of flow.json, change the address and key to your correct values

## Contributing

Pull request are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[AGPL](https://choosealicense.com/licenses/agpl-3.0/)
