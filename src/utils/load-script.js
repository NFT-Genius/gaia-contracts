import path from 'path';
import fs from 'fs';
import { NFT_CONTRACT, FUSD_CONTRACT, FUNGIBLE_TOKEN } from '../config';

export function loadScript(fileName) {
  return fs
    .readFileSync(path.join(__dirname, '../../', fileName), 'utf8')
    .replace('0xNFTContract', NFT_CONTRACT)
    .replace('0xFUSDContract', FUSD_CONTRACT)
    .replace('0xFungibleToken', FUNGIBLE_TOKEN);
}
