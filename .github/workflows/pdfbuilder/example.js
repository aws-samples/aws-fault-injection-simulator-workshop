const puppeteer = require('puppeteer');
const PDFMerger = require('pdf-merger-js');
const fs = require('fs');
const readline = require('readline');

// (async () => {
//   const browser = await puppeteer.launch();
//   const page = await browser.newPage();

//   await page.goto('https://chaos-engineering.workshop.aws/en/030_basic_content.html');
//   await page.screenshot({ path: 'example.png' });
//   await page.pdf({ format: 'letter', path: 'example.pdf' });
//   await browser.close();
// })();


// const fs = require('fs')

// fs.readFile('/tmp/run1.urls', 'utf8' , (err, data) => {
//   if (err) {
//     console.error(err)
//     return
//   } else {
//     console.log("xxx" + data)
//   }
// })

(async() => {
  // open browser
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  // create PDF merger 
  var merger = new PDFMerger();

  // open url list
  const fileStream = fs.createReadStream('/tmp/run1.urls');
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });
  // Note: we use the crlfDelay option to recognize all instances of CR LF
  // ('\r\n') in input.txt as a single line break.

  for await (const url of rl) {
    var pagePdf = "tmp.pdf";
    // Each line in input.txt will be successively available here as `line`.
    console.log(`Processing URL ${url} to file ${pagePdf}`);
    await page.goto(url);
    await page.pdf({ format: 'letter', path: pagePdf });
    merger.add(pagePdf);
  }

  await merger.save("merged.pdf");
  await browser.close();
})()