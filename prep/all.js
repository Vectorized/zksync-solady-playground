
#!/usr/bin/env node
const path = require('path');
const { runCommandSync } = require('./common.js');

async function main() {
  const scripts = [
    'remove-trailing-whitespace.js',
    'gen-zksync-erc1967factory-constants.js'
  ];
  const jsRuntime = process.argv[0];
  scripts.forEach(scriptRelPath => {
    const absScriptPath = path.join(__dirname, scriptRelPath);
    console.log('Running:', scriptRelPath);
    const scriptOutput = runCommandSync(jsRuntime, [absScriptPath]);
    console.log(scriptOutput);
  });
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
