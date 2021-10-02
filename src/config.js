require('dotenv').config({ path: '.env.development.local' });

export const {
  ACCESS_NODE,
  BLOCK_THRESHOLD,
  GRAPHQL_ENDPOINT,
  GRAPHQL_SECRET,
  NFT_INTERFACE,
  NFT_CONTRACT,
  NFT_MARKET_CONTRACT,
  FUSD_CONTRACT,
  FUNGIBLE_TOKEN,
  MINTER_ADDRESS,
  MINTER_PRIVATE_KEY,
  MINTER_ACCOUNT_INDEX
} = process.env;
