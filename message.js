const child_process = require('child_process');
const str = JSON.stringify({
  "method": "textDocument/didOpen",
  "jsonrpc": "2.0",
  "params": {
    "textDocument": {
      "uri": "file:///Users/alexandresobolevski/src/github.com/Shopify/project-64k/src/snippets/product-card.liquid",
      "version": 2,
      "languageId": "liquid",
      "text": "<html></html>"
    }
  }
})

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function run() {
  const lsp = child_process.spawn('bundle', ['exec', 'liquid-server']);
  let start, end;
  lsp.stdout.on('data', data => {
    const end = Date.now();
    console.log(data.toString())
    console.log("completed in %f ms", end - start);
  });
  lsp.stderr.on('data', data => console.log(data.toString()));
  // sleep(1000);
  while (true) {
    start = Date.now();
    lsp.stdin.write(`Content-Length: ${str.length}\r\n\r\n${str}`);
    await sleep(10000);
  }
}

async function main() {
  let statusCode = 0;
  try {
    await run();
  } catch (e) {
    console.log(e);
    statusCode = 1;
  }
  process.exit(statusCode);
}

main();
