import {config} from "@onflow/fcl"
config()
.put("accessNode.api", process.env.ACCESS_NODE)
.put("challenge.handshake", process.env.WALLET_DISCOVERY)
.put("0xProfile", process.env.APP_CONTRACT_PROFILE)
//.put("discovery.wallet.method", process.env.WALLET_DISCOVERY_METHOD)
//.put("discovery.wallet", process.env.WALLET_DISCOVERY)