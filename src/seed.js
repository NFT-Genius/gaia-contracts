import dotenv from 'dotenv';
import csv from 'csv-parser';
import fs from 'fs';
import GaiaService from './services/flow-assets-service';

import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { createObjectCsvWriter } from 'csv-writer';
import { MINTER_ADDRESS } from './config';
import AccountService from './services/account-service';

dotenv.config();

function writeCSV(output) {
  const csvWriter = createObjectCsvWriter({
    path: './seed/out.csv',
    header: [
      { id: 'templateID', title: 'templateID' },
      { id: 'setID', title: 'setID' },
      { id: 'creator', title: 'creator' }
    ]
  });
  csvWriter.writeRecords(output);
}

function importTemplates({ file, setID, creator }) {
  if (fs.existsSync(file)) {
    const templates = [];
    fs.createReadStream(file)
      .pipe(csv())
      .on('data', data => templates.push(data))
      .on('end', () => console.log('CSV file parsing complete.'))
      .on('end', async () => {
        console.log('Running blockchain transactions.');
        const output = [];
        try {
          for (let i = 0; i < templates.length; i += 1) {
            const { image, description, name } = templates[i];
            const tx = await GaiaService.createTemplate(setID, creator, {
              image,
              name,
              description
            });
            const templateID = tx.events[0].data.id;
            output.push({ templateID, setID, creator });
            console.log(JSON.stringify(tx, null, 2));
          }
        } finally {
          writeCSV(output);
        }
      });
  } else {
    console.log(`Wrong file path provided or file does not exists: "${file}"`);
  }
}

function addTemplatesToSet({ file }) {
  if (fs.existsSync(file)) {
    const templates = [];
    fs.createReadStream(file)
      .pipe(csv())
      .on('data', data => templates.push(data))
      .on('end', () => console.log('CSV file parsing complete.'))
      .on('end', async () => {
        console.log('Running blockchain transactions.');
        for (let i = 0; i < templates.length; i += 1) {
          const { templateID, setID, creator } = templates[i];
          const tx = await GaiaService.addTemplateToSet(templateID, setID, creator);
          console.log(JSON.stringify(tx, null, 2));
        }
      });
  } else {
    console.log(`Wrong file path provided or file does not exists: "${file}"`);
  }
}

function createSets({ file }) {
  if (fs.existsSync(file)) {
    const sets = [];
    fs.createReadStream(file)
      .pipe(csv())
      .on('data', data => sets.push(data))
      .on('end', () => console.log('CSV file parsing complete.'))
      .on('end', async () => {
        console.log('Running blockchain transactions.');
        for (let i = 0; i < sets.length; i += 1) {
          const { name, description, image, website, creator, marketFee } = sets[i];
          const tx = await GaiaService.createSet(
            name,
            description,
            website,
            image,
            creator,
            marketFee
          );
          console.log(JSON.stringify(tx, null, 2));
        }
      });
  } else {
    console.log(`Wrong file path provided or file does not exists: "${file}"`);
  }
}

async function mintNFTs({ destination, setID, templateIDS }) {
  for (let i = 0; i < templateIDS.length; i += 1) {
    const templateID = templateIDS[i];
    const tx = await GaiaService.mint(setID, templateID, destination);
    console.log(JSON.stringify(tx, null, 2));
  }
}

async function getBalance() {
  const balance = await AccountService.getFUSDBalance(MINTER_ADDRESS);
  console.log('-------FUSD BALANCE BELOW----------');
  console.log(' ');
  console.log(balance ? `${balance} FUSD` : balance);
  console.log(' ');
  console.log('-----------------');
}
async function setupFUSD() {
  const response = await AccountService.setupFUSD();
  console.log('-------FUSD Vault setup response BELOW----------');
  console.log(' ');
  console.log(response);
  console.log(' ');
  console.log('-----------------');
}
yargs(hideBin(process.argv))
  .command(
    'template <file> <setID> <creator>',
    'import templates from csv file',
    yargs => {
      return yargs
        .positional('file', { describe: 'csv file path' })
        .positional('setID', { describe: 'flow assets set id to register template on.' })
        .positional('creator', { describe: 'flow assets set creator address.' });
    },
    importTemplates
  )
  .command(
    'add-templates-to-set <file>',
    'import templates from csv file',
    yargs => {
      return yargs
        .positional('file', { describe: 'csv file path' })
        .positional('setID', { describe: 'flow assets set id to register template on.' })
        .positional('creator', { describe: 'flow assets set creator address.' });
    },
    addTemplatesToSet
  )
  .command(
    'set <file>',
    'create set from csv file',
    yargs => {
      return yargs.positional('file', { describe: 'csv file path' });
    },
    createSets
  )
  .command('getBalance', 'returns minter FUSD balance', getBalance)
  .command('setupFUSD', 'Setup minter FUSD Vault', setupFUSD)
  .command(
    'mint <destination> <setID> <templateIDS...>',
    'mint nfts from a given set id',
    yargs => {
      return yargs
        .positional('destination', { describe: 'flow account to store nfts' })
        .positional('setID', { describe: 'flow assets set id' })
        .positional('templateIDS', { describe: 'template ids to mint nfts from.' });
    },
    mintNFTs
  ).argv;
