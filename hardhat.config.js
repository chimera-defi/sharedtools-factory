require("dotenv");

module.exports = require("@chimera-defi/hardhat-framework").config.hardhat(require("./settings").hardhat);

// flattener
require("@chimera-defi/hardhat-framework").flattener();

const fs = require("fs");
const path = require("path");

task("flattenAll", "Flatten all files we care about").setAction(async ({}, {run}) => {
  let srcpath = "contracts";
  let files = fs.readdirSync(srcpath).map(file => `${srcpath}/${file}`);

  srcpath = `${srcpath}/factories`;
  files = files.concat(fs.readdirSync(srcpath).map(file => `${srcpath}/${file}`));

  try {
    fs.mkdirSync("flats/contracts/factories", {recursive: true});
  } catch (e) {}

  await Promise.all(
    files.map(async file => {
      if (path.extname(file) == ".sol") {
        await run("flat:get-flattened-sources", {
          files: [file],
          output: `./flats/${file}`,
        });
      }
    }),
  );
});
