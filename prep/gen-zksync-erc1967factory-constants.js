#!/usr/bin/env node
const { readSync, writeAndFmtSync, hasAnyPathSequence, forEachWalkSync, runCommandSync } = require('./common.js');

async function main() {
  console.log('Running `forge fmt`...');
  runCommandSync('forge', ['fmt']);
  console.log('Running `forge build --zksync`...');
  runCommandSync('forge', ['build', '--zksync']);

  const getJSONPath = contractName => 'zkout/' + contractName + '.sol/' + contractName + '.json';
  const getHash = contractName => ('0x' + JSON.parse(readSync(getJSONPath(contractName))).hash).replace(/^(0x)+/g, '0x');

  const srcPath = 'src/ZKsyncERC1967Factory.sol';
  const contractNamesAndConstants = {
    'ZKsyncUpgradeableBeacon': 'BEACON_HASH',
    'ZKsyncERC1967Proxy': 'PROXY_HASH',
    'ZKsyncERC1967BeaconProxy': 'BEACON_PROXY_HASH'
  };
  let src = readSync(srcPath);
  for (const contractName in contractNamesAndConstants) {
    const hash = getHash(contractName);
    const constantName = contractNamesAndConstants[contractName];
    const needle = new RegExp('bytes32\\s+public\\s+constant\\s+' + constantName + '\\s[\\s\\S]+?;');
    const replacement = 'bytes32 public constant ' + constantName + ' = ' + hash + ';';
    console.log(replacement);
    src = src.replace(needle, replacement);
  }
  writeAndFmtSync(srcPath, src);
  console.log('Running `forge fmt` again...');
  runCommandSync('forge', ['fmt']);
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
